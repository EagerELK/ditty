# frozen_string_literal: true

require 'ditty/controllers/application'

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
