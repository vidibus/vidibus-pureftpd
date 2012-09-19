$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'simplecov'
SimpleCov.start

require 'rubygems'
require 'rspec'
require 'rr'
require 'vidibus-pureftpd'

RSpec.configure do |config|
  config.mock_with :rr
end

I18n.load_path += Dir[File.join('config', 'locales', '**', '*.{rb,yml}')]
