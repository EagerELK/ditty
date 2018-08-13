require 'ditty/controllers/application'
require 'ditty/services/email'
require 'securerandom'

module Ditty
  class Auth < Application
    set track_actions: true

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Basic Plugin
    end

    def redirect_path
      return "#{settings.map_path}/" unless env['omniauth.origin']
      return "#{settings.map_path}/" if env['omniauth.origin'] =~ %r{/#{settings.map_path}/auth/?}
      env['omniauth.origin']
    end

    def failed_login
      broadcast(:user_failed_login, target: self, details: "IP: #{request.ip}")
      flash[:warning] = 'Invalid credentials. Please try again.'
      redirect "#{settings.map_path}/auth/login"
    end

    def successful_login
      self.current_user = user
      broadcast(:user_login, target: self, details: "IP: #{request.ip}")
      flash[:success] = 'Logged In'
      redirect redirect_path
    end

    before '/login' do
      return if User.where(roles: Role.find_or_create(name: 'super_admin')).count.positive?
      flash[:info] = 'Please register the super admin user.'
      redirect "#{settings.map_path}/auth/register"
    end

    # TODO: Make this work for both LDAP and Identity
    get '/login' do
      authorize ::Ditty::Identity, :login

      haml :'auth/login', locals: { title: 'Log In' }
    end

    get '/forgot-password' do
      authorize ::Ditty::Identity, :forgot_password

      haml :'auth/forgot', locals: { title: 'Forgot your password?' }
    end

    post '/forgot-password' do
      authorize ::Ditty::Identity, :forgot_password

      email = params[:email]
      identity = Identity[username: email]
      if identity
        # Update record
        token = SecureRandom.hex(16)
        identity.update(reset_token: token, reset_requested: Time.now)
        # Send Email
        reset_url = "#{request.base_url}#{settings.map_path}/reset-password?token=#{token}"
        Ditty::Services::Email.deliver(
          :forgot_password,
          email,
          locals: { identity: identity, reset_url: reset_url, request: request }
        )
      end
      flash[:info] = 'An email was sent to the email provided with instructions on how to reset your password'
      redirect '/login'
    end

    get '/reset-password' do
      authorize ::Ditty::Identity, :reset_password

      identity = Identity[reset_token: params[:token]]
      halt 404 unless identity && identity.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      haml :'auth/reset_password', locals: { title: 'Reset your password', identity: identity }
    end

    put '/reset-password' do
      authorize ::Ditty::Identity, :reset_password

      identity = Identity[reset_token: params[:token]]
      halt 404 unless identity && identity.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      identity_params = permitted_attributes(Identity, :update)

      identity.set identity_params.merge(reset_token: nil, reset_requested: nil)
      if identity.valid? && identity.save
        broadcast(:identity_update_password, target: self, details: "IP: #{request.ip}")
        flash[:success] = 'Password Updated'
        redirect "#{settings.map_path}/auth/login"
      else
        broadcast(:identity_update_password_failed, target: self, details: "IP: #{request.ip}")
        haml :'auth/reset_password', locals: { title: 'Reset your password', identity: identity }
      end
    end

    # Register Page
    get '/register' do
      authorize ::Ditty::User, :register

      identity = Identity.new
      haml :'auth/register', locals: { title: 'Register', identity: identity }
    end

    # Register Action
    post '/register/identity' do
      identity = Identity.new(params[:identity])
      user = User.new(email: identity.username)
      authorize user, :register

      begin
        DB.transaction do
          user.save
          user.add_identity identity
          broadcast(:user_register, target: self, values: { user: user }, details: "IP: #{request.ip}")
          flash[:info] = 'Successfully Registered. Please log in'
          redirect "#{settings.map_path}/auth/login"
        end
      rescue Sequel::ValidationFailed
        flash.now[:warning] = 'Could not complete the registration. Please try again.'
        haml :'auth/register', locals: { identity: identity }
      end
    end

    # Logout Action
    delete '/' do
      broadcast(:user_logout, target: self, details: "IP: #{request.ip}")
      logout
      flash[:info] = 'Logged Out'

      redirect(Ditty::Services::Settings[:logout_redirect_path] || "#{settings.map_path}/")
    end

    # Unauthenticated
    get '/unauthenticated' do
      redirect back
    end

    # Auth Failure
    get '/failure' do
      failed_login
    end

    # Identity
    # LDAP
    post '/:provider/callback' do |_provider|
      return failed_login unless env['omniauth.auth']
      user = User.first(email: env['omniauth.auth']['info']['email'])
      return failed_login if user.nil?
      successful_login
    end

    # Google OAuth login
    get '/:provider/callback' do
      return failed_login unless env['omniauth.auth']
      user = User.first(email: env['omniauth.auth']['info']['email'])
      return failed_login if user.nil?
      successful_login
    end
  end
end