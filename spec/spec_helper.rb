# frozen_string_literals: true

if ENV['COVERAGE'] || ENV['CI']
  require 'simplecov'

  SimpleCov.start do
    add_filter '/spec/'

    track_files 'lib/**/*.rb'
  end
end

ENV['RACK_ENV'] = 'test'

require 'pathname'
require 'fileutils'
require 'logger'
require 'byebug'
require 'rack/test'
require 'sidekiq/testing'
require 'simplecov'
require 'timecop'

Sidekiq.logger = nil

SPEC_BASE = Pathname.new(__FILE__).realpath.parent

$: << SPEC_BASE.parent + 'lib'
require 'colore'

def fixture(name)
  SPEC_BASE + 'fixtures' + name
end

def spec_logger
  Logger.new('spec/output.log')
end

Dir.glob((SPEC_BASE + "helpers" + "**.rb").to_s).each do |helper|
  require helper
end

module RSpecMixin
  include Rack::Test::Methods
  def app() described_class end
end

RSpec::configure do |rspec|
  rspec.tty = true
  rspec.color = true
  rspec.include RSpecMixin
end
