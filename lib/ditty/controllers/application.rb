# frozen_string_literal: true

require 'wisper'
require 'oga'
require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/param'
require 'sinatra/respond_with'
require 'ditty/helpers/views'
require 'ditty/helpers/pundit'
require 'ditty/helpers/authentication'
require 'ditty/services/logger'
require 'active_support'
require 'active_support/inflector'
require 'rack/contrib'
require 'rack/csrf'

module Ditty
  class Application < Sinatra::Base
    include ActiveSupport::Inflector

    set :root, ENV['APP_ROOT'] || ::File.expand_path(::File.dirname(__FILE__) + '/../../../')
    set :map_path, nil
    set :view_location, nil
    set :model_class, nil
    set :raise_sinatra_param_exceptions, true
    set track_actions: false

    # The order here is important, since Wisper has a deprecated method respond_with method
    helpers Wisper::Publisher
    helpers Helpers::Pundit, Helpers::Views, Helpers::Authentication
    helpers Sinatra::Param

    register Sinatra::Flash, Sinatra::RespondWith

    use Rack::Csrf, raise: ENV['APP_ENV'] == true
    use Rack::PostBodyContentTypeParser
    use Rack::MethodOverride
    use Rack::NestedParams

    helpers do
      def base_path
        settings.base_path || "#{settings.map_path}/#{dasherize(view_location)}"
      end

      def view_location
        return settings.view_location if settings.view_location
        return underscore(pluralize(demodulize(settings.model_class))) if settings.model_class
        underscore(demodulize(self.class))
      end
    end

    configure :production do
      disable :show_exceptions
      set :dump_errors, false
    end

    configure :development do
      set :show_exceptions, :after_handler
    end

    configure :production, :development do
      disable :logging
      use Rack::CommonLogger, Ditty::Services::Logger.instance
    end

    not_found do
      respond_to do |format|
        status 404
        format.html do
          haml :'404', locals: { title: '4 oh 4' }, layout: layout
        end
        format.json do
          json code: 404, errors: ['Not Found']
        end
      end
    end

    error Helpers::NotAuthenticated, ::Pundit::NotAuthorizedError do
      respond_to do |format|
        status 401
        format.html do
          flash[:warning] = 'Please log in first.'
          redirect with_layout("#{settings.map_path}/auth/login")
        end
        format.json do
          json code: 401, errors: ['Not Authenticated']
        end
      end
    end

    error Sequel::ValidationFailed do
      respond_to do |format|
        entity = env['sinatra.error'].model
        errors = env['sinatra.error'].errors
        status 400
        format.html do
          action = entity.id ? :edit : :new
          haml :"#{view_location}/#{action}", locals: { entity: entity, title: heading(action) }, layout: layout
        end
        format.json do
          json code: 400, errors: errors, full_errors: errors.full_messages
        end
      end
    end

    error Sinatra::Param::InvalidParameterError do
      respond_to do |format|
        status 400
        format.html do
          flash.now[:danger] = env['sinatra.error'].message
          haml :'400', locals: { title: '4 oh oh' }, layout: layout
        end
        format.json do
          json code: 400, errors: { env['sinatra.error'].param => env['sinatra.error'].message }, full_errors: [env['sinatra.error'].message]
        end
      end
    end

    error ::Sequel::ForeignKeyConstraintViolation do
      error = env['sinatra.error']
      broadcast(:application_error, error)
      ::Ditty::Services::Logger.instance.error error
      respond_to do |format|
        status 400
        format.html do
          haml :error, locals: { title: 'Something went wrong', error: error }, layout: layout
        end
        format.json do
          json code: 400, errors: ['Invalid Relation Specified']
        end
      end
    end

    error do
      error = env['sinatra.error']
      broadcast(:application_error, error)
      ::Ditty::Services::Logger.instance.error error
      respond_to do |format|
        status 500
        format.html do
          haml :error, locals: { title: 'Something went wrong', error: error }, layout: layout
        end
        format.json do
          json code: 500, errors: ['Something went wrong']
        end
      end
    end

    before(/.*/) do
      ::Ditty::Services::Logger.instance.debug "Running with #{self.class} - #{request.path_info}"
      if request.path =~ /.*\.json\Z/
        content_type :json
        request.path_info = request.path_info.gsub(/.json$/, '')
      elsif request.env['ACCEPT']
        content_type request.env['ACCEPT']
      else
        content_type(:json) if request.accept.count.eql?(1) && request.accept.first.to_s.eql?('*/*')
      end
    end

    after do
      return if params[:layout].nil?
      response.body = response.body.map do |resp|
        document = Oga.parse_html(resp)
        document.css('a').each do |elm|
          unless (href = elm.get('href')).nil?
            elm.set 'href', with_layout(href)
          end
        end
        document.to_xml
      end
    end
  end
end
