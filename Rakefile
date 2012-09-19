$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'bundler'
require 'rdoc/task'
require 'rspec'
require 'rspec/core/rake_task'

require 'vidibus/pureftpd/version'

Bundler::GemHelper.install_tasks

Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Vidibus::Pureftpd #{Vidibus::Pureftpd::VERSION}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << '--charset=utf-8'
end
