# Logstash input plugin
[GitHub](https://github.com/ernesrocker/logstash-input-elastic_jdbc).
This is a plugin for [Logstash](https://github.com/elastic/logstash).

RubyGems repository [logstash-input-elastic_jdbc](https://rubygems.org/gems/logstash-input-elastic_jdbc)

It is fully free and fully open source.

## How install
```sh
sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-elastic_jdbc.gem
```

## Documentation
This plugin inherit of elasticsearch(**ES**) input plugin, and added a tracking_column
using in jdbc input plugin for make a query to obtain the updates values.

Sample :
```logstash
  input{
       elastic_jdbc{
         hosts => "localhost"
         index => "documents"
         tracking_column => "last_update"
         query => '{"query":{"range":{"created":{"gte":"2021-08-13T00:17:58+00:00"}}}}'
         last_run_metadata_path => "/opt/logstash/last_run/elastic_jdbc_documents"
       }
  }
  filter {
  }
  output{
    stdout{}
  }
```  
In the sample before, we read from ES cluster, **documents** index, where documents hits have last_update field as 
a **date** type field (recommend use [Ingest pipelines](https://www.elastic.co/guide/en/elasticsearch/reference/7.x/ingest.html)),
then we look for all documents that have a field value **last_update** greater than the value stored in `/opt/logstash/last_run/elastic jdbc_documents" `.

#### Required parameters:
   * `hosts`: ES cluster url
   * `index`: ES index
   * `tracking_column`: Date field to tracking in ES index
   * `last_run_metadata_path` : File path where stored the last value from last hist readed from ES index. By the default have the date `1960-01-01`

#### Optional parameters:
   * All [logstash-input-elasticsearch](https://rubygems.org/gems/logstash-input-elasticsearch) parameters can use in this plugins.
   * `query`: By the default we use a bool query where we get a hits with `tracking column` greater that last value stored in `last_run_metadata_path`. 
   You can insert a query, but keep in mind that your query always be appended with the default query ( *if you don't need search by tracking column,
   please use [logstash-input-elasticsearch](https://rubygems.org/gems/logstash-input-elasticsearch) plugin*). 
   
   Sample, for this query parameter ``query => '{"query":{"range":{"created":{"gte":"2021-08-13T00:17:58+00:00"}}}}'``, 
   the final query using this plugin would be:
    
   ```{
       "query":{
          "bool":{
             "must":[
                  {"range": {"last_update":{"gt": "date_time_value_stored"}}},
                  {"range":{"abonado_date":{"gte": "2021-08-13T00:17:58+00:00"}}}
             ]
          }
       }, 
       "sort": [{"last_update"=>{:order=>"asc"}}]
      }
   ```
   **Note:** If you insert a sort statement inside the query, we always overwrite it with the sort statement value that shown above.

## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members  saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/ernesrocker/logstash-input-elastic_jdbc/blob/master/CONTRIBUTORS) file.
