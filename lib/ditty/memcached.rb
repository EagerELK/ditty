# frozen_string_literal: true

require 'ditty/services/logger'

Ditty::Services::Logger.info 'Setting up caching'

require 'dalli'
CACHE = Dalli::Client.new(ENV['MEMCACHED_URL'])
Sequel::Model.plugin :caching, CACHE, ignore_exceptions: true
