# frozen_string_literal: true

require 'sidekiq'

require_relative '../../lib/config'

Sidekiq.configure_server do |config|
  config.redis = Colore::C_.redis
end

Sidekiq.configure_client do |config|
  config.redis = Colore::C_.redis
end
