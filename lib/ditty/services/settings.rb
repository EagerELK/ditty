# frozen_string_literal: true

require 'yaml'
require 'erb'

module Ditty
  module Services
    module Settings
      CONFIG = './config/settings.yml'.freeze

      class << self
        def [](key)
          values[key.to_sym]
        end

        def values
          @values ||= values!
        end

        def values!
          @values = begin
            base = read
            base.merge!(base[ENV['APP_ENV'].to_sym]) if ENV['APP_ENV']
            base
          end
        end

        private

        def read
          symbolize_keys(File.exist?(CONFIG) ? YAML.safe_load(ERB.new(File.read(CONFIG)).result) : {})
        end

        def symbolize_keys(hash)
          return hash.map { |v| symbolize_keys(v) } if hash.is_a? Array
          return hash unless hash.is_a? Hash
          Hash[hash.map { |k, v| [k.to_sym, symbolize_keys(v)] }]
        end
      end
    end
  end
end
