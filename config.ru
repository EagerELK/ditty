# frozen_string_literal: true

require 'rack/protection'
use Rack::Session::Cookie,
    key: '_Ditty_session',
    # :secure=>!TEST_MODE, # Uncomment if only allowing https:// access
    secret: File.read('.session_secret')

require 'ditty/components/app'
Ditty.component :app

require 'ditty/services/authentication'
use OmniAuth::Builder do
  Ditty::Services::Authentication.config.each do |prov, config|
    provider prov, *config[:arguments]
  end
end

run Rack::URLMap.new Ditty::Components.routes
