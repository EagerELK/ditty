# frozen_string_literal: true

require 'ditty/models/user'
require 'ditty/models/role'
require 'ditty/models/identity'

module Ditty
  module Helpers
    module Authentication
      def current_user
        return anonymous_user if current_user_id.nil?
        User[current_user_id]
      end

      def current_user=(user)
        env['rack.session'] = {} if env['rack.session'].nil?
        env['rack.session']['user_id'] = user.id if user
      end

      def current_user_id
        return env['rack.session']['user_id'] if env['rack.session']
        env['omniauth.auth'].uid if env['omniauth.auth']
      end

      def authenticate
        authenticated?
      end

      def authenticated?
        current_user && !current_user.role?('anonymous')
      end

      def single_session?
        require 'ditty/services/authentication'
        Ditty::Services::Authentication.config.dig(:identity, :use_single_session) || false
      end

      def multi_factor_authentication?
        require 'ditty/services/authentication'
        Ditty::Services::Authentication.config.dig(:identity, :use_mfa) || false
      end

      def authenticate!
        raise NotAuthenticated unless authenticated?
        true
      end

      def logout
        env['rack.session'].delete('user_id') unless env['rack.session'].nil?
        env.delete('omniauth.auth')
      end

      def anonymous_user
        role = ::Ditty::Role.where(name: 'anonymous').order(:created_at).first
        ::Ditty::User.where(roles: role).first unless role.nil?
      end
    end

    class NotAuthenticated < StandardError
    end
  end
end
