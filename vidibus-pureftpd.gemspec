# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'vidibus/pureftpd'

Gem::Specification.new do |s|
  s.name        = 'vidibus-pureftpd'
  s.version     = Vidibus::Pureftpd::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Andre Pankratz'
  s.email       = 'andre@vidibus.com'
  s.homepage    = 'https://github.com/vidibus/vidibus-pureftpd'
  s.description = 'Interface for Pure-FTPd'
  s.summary     = 'Ruby module for controlling Pure-FTPd'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'vidibus-core_extensions'

  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'rspec', '~> 2'
  s.add_development_dependency 'rr'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rdoc'
  s.add_development_dependency 'simplecov'

  s.files = Dir.glob('{lib,app,config}/**/*') + %w[LICENSE README.md Rakefile]
  s.require_path = 'lib'
end
