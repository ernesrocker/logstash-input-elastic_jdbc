# encoding: utf-8
require "logstash/inputs/base"
require "logstash/inputs/elasticsearch"
require_relative "../../logstash/inputs/value_tracking"
require "logstash/json"
require "time"

# This plugin is a simple extension of Elasticsearch input plugin. We added tracking_column property
# for search in elasticsearch query all hits that contains the 'last_update' value bigger that the value_tracker.
# The value_tracker contains the last consult to that index stored in a last run file created.
# We build the query based on the above described.
# This is a sample of elastic_jdbc plugin statement:
# input {
#       # Read all documents from Elasticsearch matching the given query
#       elastic_jdbc {
#         hosts => "localhost"
#         tracking_column => "last_update"
# 	            last_run_metadata_path => "/opt/logstash/last_run/index_name"
# 	    }
#     }
#
class LogStash::Inputs::ElasticJdbc < LogStash::Inputs::Elasticsearch
  config_name "elastic_jdbc"

  # Overwrite query default of elasticsearch plugin. We build a default query in this plugins.
  config :query, :validate => :string, :default => '{}'

  #region tracking configuration
  # Path to file with last run time
  config :last_run_metadata_path, :validate => :string, :default => "#{ENV['HOME']}/.logstash_jdbc_last_run"

  # If tracking column value rather than timestamp, the column whose value is to be tracked
  config :tracking_column, :validate => :string

  # Type of tracking column. Currently only "numeric" and "timestamp"
  config :tracking_column_type, :validate => ['timestamp'], :default => 'timestamp'

  # Whether the previous run state should be preserved
  config :clean_run, :validate => :boolean, :default => false

  # Whether to save state or not in last_run_metadata_path
  config :record_last_run, :validate => :boolean, :default => true

  #endregion

  public
  def register
    if @tracking_column.nil?
      raise(LogStash::ConfigurationError, "Must set :tracking_column if :use_column_value is true.")
    end
    @value_tracker = ValueTracking.build_last_value_tracker(self)
    super
    build_query
  end # def register

  def set_value_tracker(instance)
    @value_tracker = instance
  end

  def build_query
    input_query = @base_query
    # Remove sort tag from base query. We only sort by tracking column
    input_query.delete("sort")
    time_now = Time.now.utc
    last_value = @value_tracker ? Time.parse(@value_tracker.value.to_s).iso8601 : Time.parse(time_now).iso8601
    column = @tracking_column.to_s
    query_default = {query: { bool: { must: [ {range: {column => {gt: last_value.to_s}}} ]}}}
    if !input_query.nil? and !input_query.empty?
      query_conditions = input_query["query"] 
      if query_conditions
        must_statement = query_default[:query][:bool][:must]
        final_must_cond = must_statement.append(query_conditions)
        query_default[:query][:bool][:must] = final_must_cond
      end
    end
    sort_condition = [{column => {order: "asc"}}]
    query_default[:sort] = sort_condition
    @base_query = LogStash::Json.load(query_default.to_json)
  end

  def run(output_queue)
    super
  end # def run

  def do_run_slice(output_queue, slice_id=nil)
    slice_query = @base_query
    slice_query = slice_query.merge('slice' => { 'id' => slice_id, 'max' => @slices}) unless slice_id.nil?

    slice_options = @options.merge(:body => LogStash::Json.dump(slice_query) )
    logger.info("Slice starting", slice_id: slice_id, slices: @slices) unless slice_id.nil?
    r = search_request(slice_options)

    r['hits']['hits'].each { |hit| push_hit(hit, output_queue) }
    logger.debug("Slice progress", slice_id: slice_id, slices: @slices) unless slice_id.nil?

    has_hits = r['hits']['hits'].any?

    while has_hits && r['_scroll_id'] && !stop?
      r = process_next_scroll(output_queue, r['_scroll_id'])
      logger.debug("Slice progress", slice_id: slice_id, slices: @slices) unless slice_id.nil?
      has_hits = r['has_hits']
    end
    logger.info("Slice complete", slice_id: slice_id, slices: @slices) unless slice_id.nil?
  end

  def push_hit(hit, output_queue)
    event = LogStash::Event.new(hit['_source'])

    if @docinfo
      # do not assume event[@docinfo_target] to be in-place updatable. first get it, update it, then at the end set it in the event.
      docinfo_target = event.get(@docinfo_target) || {}

      unless docinfo_target.is_a?(Hash)
        @logger.error("Elasticsearch Input: Incompatible Event, incompatible type for the docinfo_target=#{@docinfo_target} field in the `_source` document, expected a hash got:", :docinfo_target_type => docinfo_target.class, :event => event)

        # TODO: (colin) I am not sure raising is a good strategy here?
        raise Exception.new("Elasticsearch input: incompatible event")
      end

      @docinfo_fields.each do |field|
        docinfo_target[field] = hit[field]
      end

      event.set(@docinfo_target, docinfo_target)
    end

    decorate(event)
    output_queue << event
    # Write in the file the last_update value register in the event.
    @value_tracker.set_value(event.get(@tracking_column))
    @value_tracker.write
  end

  def stop
    super
  end
end # class LogStash::Inputs::ElasticJdbc
