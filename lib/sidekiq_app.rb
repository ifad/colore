#
# Application initializer for the Colore Sidekiq process. See (BASE/run_sidekiq) for usage.
#
#
require 'sidekiq'

require_relative '../config/initializers/sidekiq.rb'

require_relative 'colore'
