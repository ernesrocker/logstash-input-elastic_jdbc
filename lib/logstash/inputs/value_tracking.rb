require "yaml" # persistence
class ValueTracking

  def self.build_last_value_tracker(plugin)
    handler = NullFileHandler.new(plugin.last_run_metadata_path)
    if plugin.record_last_run
      handler = FileHandler.new(plugin.last_run_metadata_path)
    end
    if plugin.clean_run
      handler.clean
    end
    instance = DateTimeValueTracker.new(handler)
  end

  attr_reader :value

  def initialize(handler)
    @file_handler = handler
    set_value(get_initial)
  end

  def get_initial
    # override in subclass
  end

  def set_value(value)
    # override in subclass
  end

  def write
    @file_handler.write(@value.to_s)
  end
end


class DateTimeValueTracker < ValueTracking
  def get_initial
    @file_handler.read || DateTime.new(1970)
  end

  def set_value(value)
    if value.respond_to?(:to_datetime)
      @value = value.to_datetime
    else
      @value = DateTime.parse(value)
    end
  end
end

class FileHandler
  def initialize(path)
    @path = path
    @exists = ::File.exist?(@path)
  end

  def clean
    return unless @exists
    ::File.delete(@path)
    @exists = false
  end

  def read
    return unless @exists
    YAML.load(::File.read(@path))
  end

  def write(value)
    ::File.write(@path, YAML.dump(value))
    @exists = true
  end
end

class NullFileHandler
  def initialize(path)
  end

  def clean
  end

  def read
  end

  def write(value)
  end
end


