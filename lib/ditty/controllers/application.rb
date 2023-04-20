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

module Ditty
  class Application < Sinatra::Base
    include ActiveSupport::Inflector

    set :root, ENV['APP_ROOT'] || ::File.expand_path(::File.dirname(__FILE__) + '/../../../')
    set :map_path, nil
    set :view_location, nil
    set :model_class, nil
    set :raise_sinatra_param_exceptions, true

    # The order here is important, since Wisper has a deprecated method respond_with method
    helpers Wisper::Publisher
    helpers Helpers::Pundit, Helpers::Views, Helpers::Authentication
    helpers Sinatra::Param

    register Sinatra::Flash, Sinatra::RespondWith

    use Rack::PostBodyContentTypeParser
    use Rack::MethodOverride
    use Rack::NestedParams

    helpers do
      def logger
        ::Ditty::Services::Logger.instance
      end

      def base_path
        settings.base_path || "#{settings.map_path}/#{dasherize(view_location)}"
      end

      def view_location
        return settings.view_location if settings.view_location
        return underscore(pluralize(demodulize(settings.model_class))) if settings.model_class
        underscore(demodulize(self.class))
      end

      def browser
        Browser.new(request.user_agent, accept_language: request.env['HTTP_ACCEPT_LANGUAGE'])
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
          if response.body.empty?
            json code: 404, errors: ['Not Found']
          else
            [404, response.body]
          end
        end
      end
    end

    error Helpers::NotAuthenticated, ::Pundit::NotAuthorizedError do
      respond_to do |format|
        status 401
        format.html do
          flash[:warning] = 'Please log in first.'
          redirect with_layout("#{settings.map_path}/auth/identity")
        end
        format.json do
          if response.body.empty?
            json code: 401, errors: ['Not Authenticated']
          else
            [401, response.body]
          end
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
      elsif request.path =~ /.*\.csv\Z/
        content_type :csv
        request.path_info = request.path_info.gsub(/.csv$/, '')
      elsif request.env['ACCEPT']
        content_type request.env['ACCEPT']
      else
        content_type(:json) if request.accept.count.eql?(1) && request.accept.first.to_s.eql?('*/*')
      end

      if single_session?
        return if request.path_info == '/auth/identity/mfa'
        return unless respond_to?(:browser) &&
                      respond_to?(:request) &&
                      respond_to?(:current_user) &&
                      current_user.is_a?(Ditty::User) &&
                      request.path_info != '/auth/identity/callback'

        require 'ditty/models/user_login_trait'
        active_trait = current_user.user_login_traits.select { |t| t.active == true }.first
        if active_trait &&
           (active_trait.ip_address != request.ip ||
             active_trait.platform != browser.platform.name ||
             active_trait.browser != browser.name)
          logout
          return redirect "#{settings.map_path}/auth/identity"
        end
      end

      if multi_factor_authentication?
        return unless respond_to?(:request) &&
                      respond_to?(:current_user) &&
                      current_user.is_a?(Ditty::User) &&
                      !request.path_info.include?('/auth/identity')

        identity = Identity.find(user_id: current_user[:id])
        if identity && !(identity[:pin] && identity[:pin_verified])
          logout
          return redirect "#{settings.map_path}/auth/identity"
        end
      end
    end

    after do
      return if params[:layout].nil?
      return unless response.body.respond_to?(:map)

      begin
        orig = response.body
        response.body = response.body.map do |resp|
          document = Oga.parse_html(resp)
          document.css('a').each do |elm|
            unless (href = elm.get('href')).nil?
              elm.set 'href', with_layout(href)
            end
          end
          document.to_xml
        end
      rescue StandardError => _e
        orig
      end
    end
  end
end
