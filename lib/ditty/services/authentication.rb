# frozen_string_literal: true

require 'ditty/controllers/application_controller'
require 'ditty/services/settings'
require 'ditty/services/logger'

require 'omniauth'
OmniAuth.config.logger = ::Ditty::Services::Logger
OmniAuth.config.path_prefix = "#{::Ditty::ApplicationController.map_path}/auth"
OmniAuth.config.on_failure = proc { |env|
  next [400, {}, []] if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'

  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module Ditty
  module Services
    module Authentication
      class << self
        def [](key)
          config[key]
        end

        def providers
          config.compact.keys.select { |e| config[e][:available] && config[e][:enabled] != false }
        end

        def setup
          config.compact.each_key do |provider|
            ::Ditty::Services::Logger.debug "Loading authentication provider #{provider}"
            req = if config.dig(provider, :require)
              [config[provider][:require]]
            else
              ["omniauth/#{provider}", "omniauth-#{provider}"]
            end
            req.find do |e|
              require e
              config[provider][:available] = true
              true
            rescue LoadError
              ::Ditty::Services::Logger.warn "Could not load authentication provider #{provider} using #{e}"
              config[provider][:available] = false
              false
            end
          end
        end

        def config
          @config ||= default.merge(::Ditty::Services::Settings.values(:authentication) || {})
        end

        def provides?(provider)
          provider = provider.to_sym
          providers.include?(provider) && config[provider][:available] && config.dig(provider, :enabled) != false
        end

        def default
          require 'ditty/models/identity'
          require 'ditty/controllers/auth_controller'
          {
            identity: {
              available: true,
              arguments: [
                {
                  fields: [:username],
                  model: ::Ditty::Identity,
                  on_login: ::Ditty::AuthController,
                  on_registration: ::Ditty::AuthController,
                  locate_conditions: ->(req) { { username: req['username'] } }
                }
              ]
            }
          }
        end
      end
    end
  end
end

::Ditty::Services::Authentication.setup
