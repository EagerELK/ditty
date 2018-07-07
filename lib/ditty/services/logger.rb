# frozen_string_literal: true

require 'logger'
require 'yaml'
require 'singleton'
require 'active_support/inflector'
require 'ditty/services/settings'
require 'active_support/core_ext/object/blank'

module Ditty
  module Services
    class Logger
      include Singleton

      attr_reader :loggers

      def initialize
        @loggers = []
        return if config[:loggers].blank?
        config[:loggers].each do |values|
          klass = values[:class].constantize
          opts = tr(values[:options]) || nil
          logger = klass.new(opts)
          if values[:level]
            logger.level = klass.const_get(values[:level].to_sym)
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
        default.merge Ditty::Services::Settings.values(:logger) || {}
      end

      def tr(val)
        {
          '$stdout' => $stdout,
          '$stderr' => $stderr
        }[val] || val
      end

      def default
        { loggers: [{ name: 'default', class: 'Logger' }] }
      end
    end
  end
end
