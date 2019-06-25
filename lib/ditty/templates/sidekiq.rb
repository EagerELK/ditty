# frozen_string_literal: true

require 'dotenv/load'
require 'sidekiq'
require './application'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV['REDIS_URL'] }
end

Sidekiq::Logging.logger = ::Ditty::Services::Logger.instance
Sidekiq::Logging.logger.level = Logger::WARN unless ENV['SIDEKIQ_DEBUG'].nil?

::Ditty::Components.workers
