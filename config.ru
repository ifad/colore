# frozen_string_literal: true

#\ -o 0.0.0.0 -p 9240 # rubocop:disable Layout/LeadingCommentSpace
#
# Rackup config for the Colore app
#
require 'pathname'
require "sinatra"

BASE = Pathname.new(__FILE__).realpath.parent
$: << BASE
$: << BASE + 'lib'
require 'config/initializers/sidekiq'

require 'app'

require 'sidekiq/web'
require 'sidekiq/cron/web'

run Rack::URLMap.new('/' => Colore::App, '/sidekiq' => Sidekiq::Web)
