# frozen_string_literal: true

require 'ditty/controllers/application'
require 'ditty/services/email'
require 'ditty/services/authentication'
require 'securerandom'

module Ditty
  class Main < Application
    set track_actions: true

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Basic Plugin
    end

    def redirect_path
      return "#{settings.map_path}/" unless env['omniauth.origin']
      return "#{settings.map_path}/" if env['omniauth.origin'].match %r{/#{settings.map_path}/auth/?}
      env['omniauth.origin']
    end

    CHECK_PATHS = [settings.map_path, "#{settings.map_path}/auth/identity"].freeze

    before(/.*/) do
      return unless CHECK_PATHS.include? request.path
      # Redirect to the registration page if there's no SA user
      sa = Role.find_or_create(name: 'super_admin')
      if User.where(roles: sa).count == 0
        flash[:info] = 'Please register the super admin user.'
        redirect "#{settings.map_path}/auth/identity/register"
      end
    end

    # Home Page
    get '/' do
      authenticate!
      haml :index, locals: { title: 'Home' }
    end

    # OmniAuth Identity Stuff
    # Log in Page
    get '/auth/identity' do
      haml :'identity/login', locals: { title: 'Log In' }
    end

    get '/auth/identity/forgot' do
      haml :'identity/forgot', locals: { title: 'Forgot your password?' }
    end

    post '/auth/identity/forgot' do
      email = params[:email]
      identity = Identity[username: email]
      if identity
        # Update record
        token = SecureRandom.hex(16)
        identity.update(reset_token: token, reset_requested: Time.now)
        # Send Email
        reset_url = "#{request.base_url}#{settings.map_path}/auth/identity/reset?token=#{token}"
        Ditty::Services::Email.deliver(
          :forgot_password,
          email,
          locals: { identity: identity, reset_url: reset_url, request: request }
        )
      end
      flash[:info] = 'An email was sent to the email provided with instructions on how to reset your password'
      redirect '/auth/identity'
    end

    get '/auth/identity/reset' do
      identity = Identity[reset_token: params[:token]]
      halt 404 unless identity && identity.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      haml :'identity/reset', locals: { title: 'Reset your password', identity: identity }
    end

    put '/auth/identity/reset' do
      identity = Identity[reset_token: params[:token]]
      halt 404 unless identity && identity.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      identity_params = permitted_attributes(Identity, :update)

      identity.set identity_params.merge(reset_token: nil, reset_requested: nil)
      if identity.valid? && identity.save
        broadcast(:identity_update_password, target: self, details: "IP: #{request.ip}")
        flash[:success] = 'Password Updated'
        redirect "#{settings.map_path}/auth/identity"
      else
        broadcast(:identity_update_password_failed, target: self, details: "IP: #{request.ip}")
        haml :'identity/reset', locals: { title: 'Reset your password', identity: identity }
      end
    end

    get '/auth/failure' do
      broadcast(:user_failed_login, target: self, details: "IP: #{request.ip}")
      flash[:warning] = 'Invalid credentials. Please try again.'
      redirect "#{settings.map_path}/auth/identity"
    end

    # Register Page
    get '/auth/identity/register' do
      authorize ::Ditty::Identity, :register

      identity = Identity.new
      haml :'identity/register', locals: { title: 'Register', identity: identity }
    end

    # Register Action
    post '/auth/identity/new' do
      authorize ::Ditty::Identity, :register

      identity = Identity.new(params[:identity])
      begin
        DB.transaction do
          identity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect
          user = User.find(email: identity.username)
          if user.nil?
            user = User.create(email: identity.username)

            broadcast(:user_register, target: self, values: { user: user }, details: "IP: #{request.ip}")
          end
          user.add_identity identity
          flash[:info] = 'Successfully Registered. Please log in'
          redirect "#{settings.map_path}/auth/identity"
        end
      rescue Sequel::ValidationFailed
        flash.now[:warning] = 'Could not complete the registration. Please try again.'
        haml :'identity/register', locals: { identity: identity }
      end
    end

    # Logout Action
    delete '/auth/identity' do
      broadcast(:user_logout, target: self, details: "IP: #{request.ip}")
      logout
      flash[:info] = 'Logged Out'
      halt 200 if request.xhr?
      redirect("#{settings.map_path}/")
    end

    post '/auth/identity/callback' do
      if env['omniauth.auth']
        # Successful Login
        user = User.find(email: env['omniauth.auth']['info']['email'])
        self.current_user = user
        broadcast(:user_login, target: self, details: "IP: #{request.ip}")
        halt 200 if request.xhr?
        flash[:success] = 'Logged In'
        redirect redirect_path
      else
        # Failed Login
        broadcast(:identity_failed_login, target: self, details: "IP: #{request.ip}")
        flash[:warning] = 'Invalid credentials. Please try again.'
        redirect "#{settings.map_path}/auth/identity"
      end
    end

    get '/auth/:provider/callback' do
      if env['omniauth.auth']
        # Successful Login
        user = User.find(email: env['omniauth.auth']['info']['email'])
        if user.nil?
          DB.transaction do
            user = User.create(email: env['omniauth.auth']['info']['email'])
            broadcast(:user_register, target: self, values: { user: user }, details: "IP: #{request.ip}")
          end
        end
        self.current_user = user
        broadcast(:user_login, target: self, details: "IP: #{request.ip}")
        halt 200 if request.xhr?
        flash[:success] = 'Logged In'
        redirect redirect_path
      else
        # Failed Login
        broadcast(:user_failed_login, target: self, details: "IP: #{request.ip}")
        flash[:warning] = 'Invalid credentials. Please try again.'
        redirect "#{settings.map_path}/auth/identity"
      end
    end

    # Unauthenticated
    get '/unauthenticated' do
      redirect "#{settings.map_path}/auth/identity"
    end
  end
end
