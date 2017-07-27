# frozen_string_literal: true

require 'wisper'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/respond_with'
require 'ditty/helpers/views'
require 'ditty/helpers/pundit'
require 'ditty/helpers/wisper'
require 'ditty/helpers/authentication'
require 'ditty/services/logger'
require 'rack/contrib'

module Ditty
  class Application < Sinatra::Base
    set :root, ENV['APP_ROOT'] || ::File.expand_path(::File.dirname(__FILE__) + '/../../../')
    set :view_location, nil
    set :model_class, nil
    # The order here is important, since Wisper has a deprecated method respond_with method
    helpers Wisper::Publisher, Helpers::Wisper
    helpers Helpers::Pundit, Helpers::Views, Helpers::Authentication

    register Sinatra::Flash, Sinatra::RespondWith

    use Rack::PostBodyContentTypeParser
    use Rack::MethodOverride

    configure :production do
      disable :show_exceptions
    end

    configure :development do
      set :show_exceptions, :after_handler
    end

    configure :production, :development do
      enable :logging
      # use Rack::CommonLogger, Ditty::Services::Logger.instance
    end

    not_found do
      haml :'404', locals: { title: '4 oh 4' }
    end

    error do
      error = env['sinatra.error']
      haml :error, locals: { title: 'Something went wrong', message: error }
    end

    error Helpers::NotAuthenticated do
      flash[:warning] = 'Please log in first.'
      redirect '/auth/identity'
    end

    error ::Pundit::NotAuthorizedError do
      flash[:warning] = 'Please log in first.'
      redirect '/auth/identity'
    end

    before(/.*/) do
      ::Ditty::Services::Logger.instance.debug "Running with #{self.class}"
      if request.url =~ /.json/
        request.accept.unshift('application/json')
        request.path_info = request.path_info.gsub(/.json/, '')
      end
    end
  end
end
