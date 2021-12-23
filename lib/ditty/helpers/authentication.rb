# frozen_string_literal: true

require 'ditty/models/user'

module Ditty
  module Helpers
    module Authentication
      def current_user
        return nil if current_user_id.nil?

        @current_user ||= User[current_user_id]
      rescue Sequel::DatabaseError => e
        Services::Logger.warn "Could not fetch current user: #{e.message}"
        Services::Logger.debug e
        Sentry.capture_exception(e)
        nil
      end

      def current_user=(user)
        env['rack.session'] = {} if env['rack.session'].nil?
        env['rack.session']['user_id'] = user.id if user
        @current_user = user
      end

      def current_user_id
        return env['rack.session']['user_id'] if env['rack.session'] && env['rack.session']['user_id']

        env['omniauth.auth']&.uid
      end

      def authenticate
        authenticated?
      end

      def authenticated?
        current_user && !current_user.role?('anonymous')
      end

      def authenticate!
        raise NotAuthenticated unless authenticated?

        true
      end

      def logout
        env['rack.session']&.delete('user_id')
        env.delete('omniauth.auth')
      end
    end

    class NotAuthenticated < StandardError
    end
  end
end
