# frozen_string_literal: true

require 'ditty/models/user'
require 'ditty/models/role'
require 'ditty/models/identity'

module Ditty
  module Helpers
    module Authentication
      def current_user
        user_id = current_user_id
        self.current_user = anonymous_user if user_id.nil?
        @users ||= Hash.new { |h, k| h[k] = User[k] }
        @users[user_id] unless user_id.nil?
      end

      def current_user=(user)
        env['rack.session'] = {} if env['rack.session'].nil?
        env['rack.session']['user_id'] = user.id if user
      end

      def current_user_id
        return env['omniauth.auth'].uid if env['omniauth.auth']
        env['rack.session']['user_id'] if env['rack.session']
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
        env['rack.session'].delete('user_id')
      end

      def check_basic(request)
        auth = Rack::Auth::Basic::Request.new(request.env)
        return false unless auth.provided? && auth.basic?

        identity = ::Ditty::Identity.find(username: auth.credentials[0])
        identity ||= ::Ditty::Identity.find(username: CGI.unescape(auth.credentials[0]))
        return false unless identity
        self.current_user = identity.user if identity.authenticate(auth.credentials[1])
      end

      def anonymous_user
        return @anonymous_user if defined? @anonymous_user
        @anonymous_user ||= begin
          role = ::Ditty::Role.where(name: 'anonymous').first
          ::Ditty::User.where(roles: role).first unless role.nil?
        end
      end
    end

    class NotAuthenticated < StandardError
    end
  end
end
