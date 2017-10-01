# frozen_string_literal: true

require 'rack/protection'
use Rack::Session::Cookie,
    key: '_Ditty_session',
    # :secure=>!TEST_MODE, # Uncomment if only allowing https:// access
    secret: File.read('.session_secret')
use Rack::Protection::RemoteToken
use Rack::Protection::SessionHijacking

require 'ditty/components/app'
Ditty.component :app

require 'omniauth'
require 'omniauth/identity'
OmniAuth.config.logger = Ditty::Services::Logger.instance
OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}
require 'ditty/controllers/main'
require 'ditty/models/identity'
use OmniAuth::Builder do
  # The identity provider is used by the App.
  provider :identity,
           fields: [:username],
           callback_path: '/auth/identity/callback',
           model: Ditty::Identity,
           on_login: Ditty::Main,
           on_registration: Ditty::Main,
           locate_conditions: ->(req) { { username: req['username'] } }
end

run Rack::URLMap.new Ditty::Components.routes
