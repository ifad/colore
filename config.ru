#\ -o 0.0.0.0 -p 9240
#
# Rackup config for the Colore app
#
require 'sinatra'

require_relative 'config/initializers/sidekiq'
require_relative 'lib/app'

require_relative 'lib/sidekiq/web'
require_relative 'lib/sidekiq/cron/web'

run Rack::URLMap.new('/' => Colore::App, '/sidekiq' => Sidekiq::Web)
