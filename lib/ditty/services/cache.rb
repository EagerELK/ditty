# frozen_string_literal: true

require 'dalli'
require 'net/telnet'

module Ditty
  module Services
    class Cache
      attr_writer :store
      attr_accessor :ttl
      attr_accessor :namespace

      def initialize(store: nil, ttl: 3_600, namespace: 'Ditty')
        @store = store
        @ttl = ttl
        @namespace = namespace
      end

      def store
        @store ||= Dalli::Client.new(ENV.fetch('CACHE_URL'), namespace: namespace)
      end

      def set(key, obj)
        store.set(key, obj, ttl)
        obj
      end

      def get(key)
        store.get(key)
      rescue Memcached::ServerIsMarkedDead => e
        logger.warn "Could not retrieve cache key #{key}: #{e.message}"
        nil
      end

      def clear(key)
        delete(key)
      end

      def delete(key)
        store.delete(key)
      end

      def dump
        cache_items.map do |key, expires_at|
          {
            key: key,
            value: get(key),
            expires_at: expires_at
          }
        end
      end

      def empty
        count = 0
        cache_items.keys.each do |key|
          delete(key)
          count = count + 1
        end
        count
      end

      private

      def cache_uri
        @cache_uri ||= URI("memcached://#{ENV.fetch('CACHE_URL')}")
      end

      def connection
        @connection ||= Net::Telnet::new("Host" => cache_uri.host, "Port" => cache_uri.port, "Timeout" => 30)
      end

      def slab_ids
        slab_ids = []
        connection.cmd('String' => 'stats items', 'Match' => /^END/) do |result|
          slab_ids = result.scan(/STAT items:(\d+):/).flatten.uniq
        end
        slab_ids
      end

      def cache_items
        items = {}
        slab_ids.each do |slab_id|
          connection.cmd("String" => "stats cachedump #{slab_id} 100", "Match" => /^END/) do |result|
            matches = result.scan(/^ITEM (.+?) \[(\d+) b; (\d+) s\]$/).each do |key_data|
              (cache_key, bytes, expires_time) = key_data
              humanized_expires_time = Time.at(expires_time.to_i).to_s
              items[cache_key.sub(/^#{namespace}:/, '')] = Time.at(expires_time.to_i)
            end
          end
        end
        items
      end
    end
  end
end

module URI
  class Memcached < Generic
    DEFAULT_PORT = 11211
  end
  register_scheme 'Memcached', Memcached
end
