# Bundler
require 'bundler/setup'

# RSpec
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

# YARD
require 'yard'
YARD::Rake::YardocTask.new

# Rollbar
require 'rollbar/rake_tasks'
task :environment do
  Rollbar.configure do |config|
    config.access_token = '4d1ae93436594677844a781e7812faed'
  end
end

task default: [:spec, :yard]
