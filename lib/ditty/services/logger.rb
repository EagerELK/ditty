# frozen_string_literal: true

require 'logger'
require 'yaml'
require 'singleton'
require 'active_support/inflector'

module Ditty
  module Services
    class Logger
      include Singleton

      CONFIG = './config/logger.yml'.freeze
      attr_reader :loggers

      def initialize
        @loggers = []
        config.each do |values|
          klass = values['class'].constantize
          opts = tr(values['options']) || nil
          logger = klass.new(opts)
          if values['level']
            logger.level = klass.const_get(values['level'].to_sym)
          end
          @loggers << logger
        end
      end

      def method_missing(method, *args, &block)
        loggers.each { |logger| logger.send(method, *args, &block) }
      end

      def respond_to_missing?(method, _include_private = false)
        loggers.any? { |logger| logger.respond_to?(method) }
      end

      private

      def config
        @config ||= File.exist?(CONFIG) ? YAML.load_file(CONFIG) : default
      end

      def tr(val)
        {
          '$stdout' => $stdout,
          '$stderr' => $stderr
        }[val] || val
      end

      def default
        [{ 'name' => 'default', 'class' => 'Logger' }]
      end
    end
  end
end
