# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'wisper'

module Ditty
  class Listener
    EVENTS = %i[
      component_list component_create component_read component_update component_delete
      identity_register identity_login identity_logout identity_failed_login identity_update_password
      identity_update_password_failed
    ].freeze

    def initialize
      @mutex = Mutex.new
    end

    def method_missing(method, *args)
      return unless args[0].is_a?(Hash) && args[0][:target] && args[0][:target].settings.track_actions

      log_action({
        user: args[0][:target].current_user,
        action: action_from(args[0][:target], method),
        details: args[0][:details]
      }.merge(args[0][:values] || {}))
    end

    def respond_to_missing?(method, _include_private = false)
      EVENTS.include? method
    end

    def action_from(target, method)
      return method unless method.to_s.start_with? 'component_'
      target.class.to_s.demodulize.underscore + '_' + method.to_s.gsub(/^component_/, '')
    end

    def log_action(values)
      values[:user] ||= values[:target].current_user if values[:target]
      @mutex.synchronize { Ditty::AuditLog.create values }
    end
  end
end

Wisper.subscribe(Ditty::Listener.new) unless ENV['RACK_ENV'] == 'test'
