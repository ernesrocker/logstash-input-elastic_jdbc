# coding: utf-8
Gem::Specification.new do |s|
  s.name          = 'logstash-input-elastic_jdbc'
  s.version       = '1.0.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Reads querys from Elasticsearch cluster and write last run file.'
  s.description   = 'This gem is a Logstash plugin required to be installed on top of the Logstash core pipeline using $LS_HOME/bin/logstash-plugin install gemname.
                     This gem is not a stand-alone program. Also, this plugin inherit of elasticsearch input plugin, but added tracking_column like jdbc input plugin.'
  s.homepage      = 'https://github.com/ernesrocker/logstash-input-elastic_jdbc'
  s.authors       = ['Ernesto Soler Calaña']
  s.email         = 'ernes920825@gmail.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "input" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency 'logstash-codec-plain'
  s.add_runtime_dependency 'stud', '>= 0.0.22'
  s.add_development_dependency 'logstash-devutils', '~> 0.0', '>= 0.0.16'
  s.add_development_dependency 'logstash-input-elasticsearch', '>= 4.3.1'
end
