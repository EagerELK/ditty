# frozen_string_literal: true

require 'ditty/controllers/application'
require 'ditty/emails/forgot_password'
require 'securerandom'

module Ditty
  class Main < Application
    set track_actions: true

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Basic Plugin
    end

    # Home Page
    get '/' do
      authenticate!
      haml :index, locals: { title: 'Home' }
    end

    # OmniAuth Identity Stuff
    # Log in Page
    get '/auth/identity' do
      # Redirect to the registration page if there's no SA user
      sa = Role.find_or_create(name: 'super_admin')
      if User.where(roles: sa).count == 0
        flash[:info] = 'Please register the super admin user.'
        redirect "#{settings.map_path}/auth/identity/register"
      end
      haml :'identity/login', locals: { title: 'Log In' }
    end

    get '/auth/identity/forgot' do
      haml :'identity/forgot', locals: { title: 'Forgot your password?' }
    end

    post '/auth/identity/forgot' do
      email = params['email']
      identity = Identity[username: email]
      if identity
        # Update record
        token = SecureRandom.hex(16)
        identity.update(reset_token: token, reset_requested: Time.now)
        # Send Email
        reset_url = "#{request.base_url}#{settings.map_path}/auth/identity/reset?token=#{token}"
        Ditty::Emails::ForgotPassword.deliver(email, identity: identity, reset_url: reset_url, request: request)
      end
      flash[:info] = 'An email was sent to the email provided with instructions on how to reset your password'
      redirect '/auth/identity'
    end

    get '/auth/identity/reset' do
      identity = Identity[reset_token: params['token']]
      halt 404 unless identity && identity.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      haml :'identity/reset', locals: { title: 'Reset your password' }
    end

    put '/auth/identity/reset' do
      identity = Identity[reset_token: params['token']]
      halt 404 unless identity && identity.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      identity_params = permitted_attributes(Identity, :update)

      unless identity_params['password'] == identity_params['password_confirmation']
        flash[:warning] = 'Password didn\'t match'
        return redirect back
      end

      identity.set identity_params.merge(reset_token: nil, reset_requested: nil)
      if identity.valid? && identity.save
        # log_action("#{dehumanized}_update_password".to_sym) if settings.track_actions
        flash[:success] = 'Password Updated'
      end
      redirect "#{settings.map_path}/auth/identity"
    end

    get '/auth/failure' do
      broadcast(:identity_failed_login, target: self)
      flash[:warning] = 'Invalid credentials. Please try again.'
      redirect "#{settings.map_path}/auth/identity"
    end

    post '/auth/identity/callback' do
      if env['omniauth.auth']
        # Successful Login
        user = User.find(email: env['omniauth.auth']['info']['email'])
        self.current_user = user
        broadcast(:identity_login, target: self)
        flash[:success] = 'Logged In'
        redirect env['omniauth.origin'] || "#{settings.map_path}/"
      else
        # Failed Login
        broadcast(:identity_failed_login, target: self)
        flash[:warning] = 'Invalid credentials. Please try again.'
        redirect "#{settings.map_path}/auth/identity"
      end
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

      identity = Identity.new(params['identity'])
      if identity.valid? && identity.save
        user = User.find_or_create(email: identity.username)
        user.add_identity identity

        # Create the SA user if none is present
        sa = Role.find_or_create(name: 'super_admin')
        user.add_role sa if User.where(roles: sa).count == 0

        broadcast(:identity_register, target: self, values: { user: user })
        flash[:info] = 'Successfully Registered. Please log in'
        redirect "#{settings.map_path}/auth/identity"
      else
        flash.now[:warning] = 'Could not complete the registration. Please try again.'
        haml :'identity/register', locals: { identity: identity }
      end
    end

    # Logout Action
    delete '/auth/identity' do
      broadcast(:identity_logout, target: self)
      logout
      flash[:info] = 'Logged Out'

      redirect "#{settings.map_path}/"
    end

    # Unauthenticated
    get '/unauthenticated' do
      redirect "#{settings.map_path}/auth/identity"
    end
  end
end
