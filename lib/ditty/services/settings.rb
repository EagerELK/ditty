# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'

module Ditty
  module Services
    module Settings
      CONFIG_FOLDER = './config'.freeze

      class << self
        def [](key)
          values[key.to_sym]
        end

        def values(scope = :settings)
          @values ||= Hash.new do |h, k|
            h[k] = read("#{CONFIG_FOLDER}/#{k}.yml") if File.file?("#{CONFIG_FOLDER}/#{k}.yml")
            h[k] = h[:settings][k] if h.key?(k) == false && h.key?(:settings) && k != :settings
            h.key?(k) ? h[k] : {}
          end
          @values[scope]
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
