require 'ditty/models/identity'
require 'ditty/controllers/main'
require 'ditty/services/settings'

module Ditty
  module Services
    module Authentication
      class << self
        def providers
          config.keys
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
                  on_login: Ditty::Main,
                  on_registration: Ditty::Main,
                  locate_conditions: ->(req) { { username: req['username'] } }
                }
              ],
            }
          }
        end
      end
    end
  end
end
