# frozen_string_literal: true

require 'dalli'

module Ditty
  module Services
    class Cache
      attr_writer :store
      attr_accessor :ttl

      def initialize(store: nil, ttl: 3_600)
        @store = store
        @ttl = ttl
      end

      def store
        @store ||= Dalli::Client.new(ENV.fetch('CACHE_URL'), namespace: 'Ditty')
      end

      def set(key, obj)
        store.set(key, obj, ttl)
        obj
      end

      def get(key)
        store.get(key)
      end

      def clear(key)
        delete(key)
      end

      def delete(key)
        store.delete(key)
      end
    end
  end
end
