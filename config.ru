# frozen_string_literal: true

#\ -o 0.0.0.0 -p 9240 # rubocop:disable Layout/LeadingCommentSpace
#
# Rackup config for the Colore app
#
require "sinatra"

require_relative 'config/initializers/sidekiq'
require_relative 'lib/app'

require 'sidekiq/web'
require 'sidekiq/cron/web'

run Rack::URLMap.new('/' => Colore::App, '/sidekiq' => Sidekiq::Web)
