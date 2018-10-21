require 'ditty/controllers/application'
require 'ditty/services/settings'
require 'ditty/services/logger'
require 'backports/2.4.0/hash/compact'

require 'omniauth'
OmniAuth.config.logger = Ditty::Services::Logger.instance
OmniAuth.config.path_prefix = "#{Ditty::Application.map_path}/auth"
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
          require 'ditty/models/identity'
          require 'ditty/controllers/auth'
          {
            identity: {
              arguments: [
                {
                  fields: [:username],
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
