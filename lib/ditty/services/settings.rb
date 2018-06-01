# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'

module Ditty
  module Services
    module Settings
      CONFIG_FOLDER = './config'.freeze
      CONFIG_FILE = "#{CONFIG_FOLDER}/settings.yml".freeze

      class << self
        def [](key)
          values(key.to_sym)
        end

        def values(scope = :settings)
          @values ||= begin
            v = Hash.new do |h, k|
              h[k] = if File.file?("#{CONFIG_FOLDER}/#{k}.yml")
                       read("#{CONFIG_FOLDER}/#{k}.yml")
                     elsif k != :settings && h[:settings].key?(k)
                       h[:settings][k]
                     end
              h[k]
            end
            v[:settings] = File.file?(CONFIG_FILE) ? read(CONFIG_FILE) : {}
            v
          end
          @values[scope]
        end

        def values=(values)
          @values = values
        end

        def read(filename)
          base = YAML.safe_load(ERB.new(File.read(filename)).result).deep_symbolize_keys
          base.deep_merge!(base[ENV['APP_ENV'].to_sym]) unless ENV['APP_ENV'].nil? || base[ENV['APP_ENV'].to_sym].nil?
          base
        end
      end
    end
  end
end
