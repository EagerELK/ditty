# frozen_string_literal: true

require 'dotenv/load'

# Last Gasp Effort to catch the error
require 'ditty/middleware/error_catchall'
use ::Ditty::Middleware::ErrorCatchall if ENV['APP_ENV'] == 'production'

# Session
use Rack::Session::Cookie,
    key: '_Ditty_session',
    path: '/',
    # :secure=>!TEST_MODE, # Uncomment if only allowing https:// access
    secret: File.read('.session_secret')

require './application'
require 'ditty/services/authentication'
use OmniAuth::Builder do
  ::Ditty::Services::Authentication.config.each do |prov, config|
    provider prov, *config[:arguments]
  end
end

map '/' do
  use Rack::Static, root: 'public', urls: ['/css', '/images', '/js'], header_rules: [
    [:all, { 'Cache-Control' => 'public, max-age=31536000' }]
  ]
  require 'ditty/middleware/accept_extension'
  use Ditty::Middleware::AcceptExtension
  require 'rack/content_type'
  use Rack::ContentType

  run Rack::URLMap.new ::Ditty::Components.routes
end
