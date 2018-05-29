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

        def config!
          cfg = config
          Mail.defaults do
            delivery_method cfg[:delivery_method].to_sym, (cfg[:options] || {})
          end
        end

        def deliver(email, to = nil, options = {})
          config!
          options[:to] ||= to unless to.nil?
          email = from_symbol(email, options) if email.is_a? Symbol
          email.deliver!
        end

        private

        def config
          default.merge Ditty::Services::Settings.values(:email)
        end

        def default
          { delivery_method: :logger, logger: Ditty::Services::Logger.instance }
        end

        def from_symbol(email, options)
          require "ditty/emails/#{email}"
          constantize("Ditty::Emails::#{classify(email)}").new(options)
        end
      end
    end
  end
end
