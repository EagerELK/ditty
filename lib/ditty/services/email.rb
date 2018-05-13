# frozen_string_literal: true

require 'mail'
require 'ditty/services/logger'

module Ditty
  module Services
    module Email
      CONFIG = './config/email.yml'.freeze

      class << self
        def create
          config!
          Mail.new
        end

        def config
          @config ||= symbolize_keys File.exist?(CONFIG) ? YAML.load_file(CONFIG) : default
        end

        private

        def config!
          cfg = config
          Mail.defaults do
            delivery_method cfg[:delivery_method].to_sym, (cfg[:options] || {})
          end
        end

        def default
          { delivery_method: :logger, logger: Ditty::Services::Logger.instance }
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
