# frozen_string_literal: true

require 'mail'
require 'active_support/inflector'
require 'ditty/services/logger'
require 'ditty/services/settings'

module Ditty
  module Services
    module Email
      class << self
        include ActiveSupport::Inflector

        attr_writer :config

        def config!
          cfg = config
          Mail.defaults do
            delivery_method cfg[:delivery_method].to_sym, (cfg[:options] || {})
          end
        end

        def generate(email, to = nil, options = {})
          config!
          options[:to] ||= to unless to.nil?
          options[:from] ||= config[:from] unless config[:from].nil?
          email = from_symbol(email, options) if email.is_a? Symbol
          email
        end

        def deliver(email, to = nil, options = {})
          generate(email, to, options).deliver!
        end

        private

          def config
            @config ||= default.merge ::Ditty::Services::Settings.values(:email) || {}
          end

          def default
            {
              delivery_method: :logger,
              logger: ::Ditty::Services::Logger
            }
          end

          def from_symbol(email, options)
            require "ditty/emails/#{email}"
            constantize("Ditty::Emails::#{classify(email)}").new(options)
          end
      end
    end
  end
end
