require 'ditty/models/identity'
require 'ditty/controllers/auth'
require 'ditty/services/settings'
require 'ditty/services/logger'

require 'omniauth'
OmniAuth.config.logger = Ditty::Services::Logger.instance
OmniAuth.config.on_failure = proc { |env|
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
          config.compact.keys
        end

        def setup
          providers.each do |provider|
            begin
              require "omniauth/#{provider}"
            rescue LoadError
              require "omniauth-#{provider}"
            end
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
                  path_prefix: '/_proxes/auth',
                  callback_path: '/_proxes/auth/identity/callback',
                  model: Ditty::Identity,
                  on_login: Ditty::Auth,
                  on_registration: Ditty::Auth,
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
