# frozen_string_literal: true

require 'yaml'
require 'erb'
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/keys'

module Ditty
  module Services
    # This is the central settings service Ditty. It is used to get the settings
    # for various aspects of Ditty, and can also be used to configure your own
    # application.
    #
    # It has the concept of sections which can either be included in the main
    # settings.yml file, or as separate files in the `config` folder. The values
    # in separate files will be used in preference of those in the `settings.yml`
    # file.
    module Settings
      CONFIG_FOLDER = './config'
      CONFIG_FILE = "#{CONFIG_FOLDER}/settings.yml"

      class << self
        def [](key)
          keys = key.to_s.split('.').map(&:to_sym)
          values[key.to_sym] || values.dig(*keys)
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

        attr_writer :values

        def read(filename)
          base = YAML.safe_load(ERB.new(File.read(filename)).result).deep_symbolize_keys
          base.deep_merge!(base[ENV['APP_ENV'].to_sym]) unless ENV['APP_ENV'].nil? || base[ENV['APP_ENV'].to_sym].nil?
          base
        end
      end
    end
  end
end
