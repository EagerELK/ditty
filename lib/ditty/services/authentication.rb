require 'ditty/models/identity'
require 'ditty/controllers/main'
require 'ditty/services/settings'
require 'ditty/services/logger'

require 'omniauth'
OmniAuth.config.logger = Ditty::Services::Logger.instance
OmniAuth.config.on_failure = proc { |env|
  next [400, {}, []] if env['HTTP_X_REQUESTED_WITH'] == 'XMLHttpRequest'
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

module Ditty
  module Services
    module Authentication
      class << self
        def providers
          config.keys
        end

        def setup
          providers.each do |provider|
            req = config.dig(provider, :require) || "omniauth/#{provider}"
            require req
          end
        end

        def config
          default.merge Ditty::Services::Settings.values(:authentication) || {}
        end

        def provides?(provider)
          providers.include? provider.to_sym
        end

        def default
          {
            identity: {
              arguments: [
                {
                  fields: [:username],
                  callback_path: '/auth/identity/callback',
                  model: Ditty::Identity,
                  on_login: ::Ditty::Main,
                  on_registration: ::Ditty::Main,
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

Ditty::Services::Authentication.setup
