# frozen_string_literal: true

require 'active_support'
require 'active_support/inflector'
require 'ditty/models/user_login_trait'
require 'wisper'
require 'browser'

module Ditty
  class Listener
    EVENTS = %i[
      component_list component_create component_read component_update component_delete
      user_register user_login user_logout user_failed_login
      identity_update_password identity_update_password_failed
    ].freeze

    def initialize
      @mutex = Mutex.new
    end

    def method_missing(method, *args)
      return unless args[0].is_a?(Hash) && args[0][:target].is_a?(Sinatra::Base) && args[0][:target].settings.track_actions

      log_action({
        user: args[0][:target].current_user,
        action: action_from(args[0][:target], method),
        details: args[0][:details]
      }.merge(args[0][:values] || {}))
    end

    def respond_to_missing?(method, _include_private = false)
      EVENTS.include? method
    end

    def user_register(event)
      user = event[:values][:user]
      log_action({
        user: user,
        action: action_from(event[:target], :user_register),
        details: event[:details]
      }.merge(event[:values] || {}))

      # Create the SA user if none is present
      sa = Role.find_or_create(name: 'super_admin')
      return if User.where(roles: sa).count.positive?
      user.add_role sa
    end

    def action_from(target, method)
      return method unless method.to_s.start_with? 'component_'
      target.class.to_s.demodulize.underscore + '_' + method.to_s.gsub(/^component_/, '')
    end

    def log_action(values)
      values[:user] ||= values[:target].current_user if values[:target]
      values[:user] = nil unless values[:user].is_a? Ditty::User
      @mutex.synchronize { Ditty::AuditLog.create values }
    end

    def user_login(event)
      #TODO: Check for existing active sessions and marks them inactive
      target = event[:target]
      if target.current_user.is_a? Ditty::User
        user = target.current_user
        traits = user.user_login_traits.select{ |trait| trait.active }
        traits.each do |trait|
          trait.active = false
          trait.save
        end
      end


      log_action(
        user_traits(event[:target]).merge(
          action: action_from(event[:target], :user_login),
          details: event[:details]
        ).merge(event[:values] || {})
      )

      @mutex.synchronize do
        traits = user_traits(event[:target])
        UserLoginTrait.update_or_create(user_traits(event[:target]), updated_at: Time.now) unless traits.empty?
      end
    end

    def user_traits(target)
      return {} unless target.respond_to?(:current_user) && target.respond_to?(:browser)
      {
        user_id: target.current_user&.id,
        platform: target.browser.platform.name,
        device: target.browser.device.name,
        browser: target.browser.name,
        ip_address: target.request.ip,
        active: true,
      }
    end
  end
end

Wisper.subscribe(Ditty::Listener.new) unless ENV['RACK_ENV'] == 'test'
