# frozen_string_literal: true

require 'ditty/controllers/application_controller'
require 'ditty/services/email'
require 'securerandom'

module Ditty
  class AuthController < ApplicationController
    set track_actions: true

    def redirect_path
      return "#{settings.map_path}/" if omniauth_redirect_path.nil?
      return "#{settings.map_path}/" if omniauth_redirect_path =~ %r{/#{settings.map_path}/auth/?}

      omniauth_redirect_path
    end

    def omniauth_redirect_path
      env['omniauth.origin'] || request.session['omniauth.origin']
    end

    def omniauth_callback(provider)
      return failed_login unless env['omniauth.auth']

      broadcast("before_#{provider}_login".to_sym, env['omniauth.auth'])
      user = User.first(email: env['omniauth.auth']['info']['email'])
      user = register_user if user.nil? && authorize(current_user, :register?)
      return failed_login if user.nil?

      broadcast("#{provider}_login".to_sym, user)
      successful_login(user)
    end

    def failed_login
      details = params[:message] || 'None'
      logger.warn "Invalid Login: #{details}"
      broadcast(:user_failed_login, target: self, details: details)
      flash[:warning] = 'Invalid credentials. Please try again'
      headers 'X-Authentication-Failure' => params[:message] if params[:message]
      redirect "#{settings.map_path}/auth/login"
    end

    def successful_login(user)
      halt 200 if request.xhr?
      self.current_user = user
      broadcast(:user_login, target: self)
      flash[:success] = 'Logged In'
      redirect redirect_path
    end

    def register_user
      user = User.create(email: env['omniauth.auth']['info']['email'])
      broadcast(:user_register, target: self, values: { user: user })
      flash[:info] = 'Successfully Registered.'
      user
    end

    before '/login' do
      return if User.where(roles: Role.find_or_create(name: 'super_admin')).count.positive?

      flash[:info] = 'Please register the super admin user.'
      redirect "#{settings.map_path}/auth/register"
    end

    # TODO: Make this work for both LDAP and Identity
    get '/login' do
      authorize ::Ditty::Identity, :login
      redirect settings.map_path if authenticated?

      haml :'auth/login', locals: { title: 'Log In' }, layout: :blank
    end

    # Custom login form for LDAP to allow CSRF checks. Set the `request_path` for
    # the omniauth-ldap provider to another path so that this gest triggered
    get '/ldap' do
      authorize ::Ditty::Identity, :login
      redirect settings.map_path if authenticated?

      haml :'auth/ldap', locals: { title: 'Company Log In' }, layout: :blank
    end

    get '/forgot-password' do
      authorize ::Ditty::Identity, :forgot_password

      haml :'auth/forgot_password', locals: { title: 'Forgot your password?' }, layout: :blank
    end

    post '/forgot-password' do
      authorize ::Ditty::Identity, :forgot_password

      param :email, String, required: true
      email = params[:email]
      identity = Identity[username: email]
      if identity
        # Update record
        token = SecureRandom.hex(16)
        identity.update(reset_token: token, reset_requested: Time.now)
        # Send Email
        reset_url = "#{request.base_url}#{settings.map_path}/reset-password?token=#{token}"
        ::Ditty::Services::Email.deliver(
          :forgot_password,
          email,
          locals: { identity: identity, reset_url: reset_url, request: request }
        )
      end
      flash[:info] = 'An email was sent to the email provided with instructions on how to reset your password'
      redirect '/login'
    end

    get '/reset-password' do
      authorize ::Ditty::Identity.new, :reset_password

      param :token, String, required: true
      identity = Identity[reset_token: params[:token]]
      halt 404 unless identity&.reset_requested && identity.reset_requested > (Time.now - (24 * 60 * 60))

      haml :'auth/reset_password', locals: { title: 'Reset your password', identity: identity }, layout: :blank
    end

    put '/reset-password' do
      param :token, String, required: true
      identity = Identity[reset_token: params[:token]]

      halt 404 unless identity
      authorize identity, :reset_password

      identity_params = permitted_attributes(Identity, :update)
      identity.set identity_params.merge(reset_token: nil, reset_requested: nil)
      if identity.valid? && identity.save
        broadcast(:identity_update_password, target: self)
        flash[:success] = 'Password Updated'
        redirect "#{settings.map_path}/auth/login"
      else
        broadcast(:identity_update_password_failed, target: self)
        haml :'auth/reset_password', locals: { title: 'Reset your password', identity: identity }, layout: :blank
      end
    end

    # Register Page
    get '/register' do
      authorize ::Ditty::User.new, :register

      identity = Identity.new
      haml :'auth/register', locals: { title: 'Register', identity: identity }, layout: :blank
    end

    # Register Action
    post '/register/identity' do
      param :identity, Hash, required: true
      identity = Identity.new(params[:identity])
      user = User.new(email: identity.username)
      authorize user, :register

      begin
        identity.valid?
        DB.transaction do
          user.save
          user.add_identity identity
          broadcast(:user_register, target: self, values: { user: user })
          flash[:info] = 'Successfully Registered. Please log in'
          redirect "#{settings.map_path}/auth/login"
        end
      rescue Sequel::ValidationFailed
        flash.now[:warning] = 'Could not complete the registration. Please try again.'
        haml :'auth/register', locals: { identity: identity }, layout: :blank
      end
    end

    # Logout Action
    delete '/' do
      broadcast(:user_logout, target: self)
      logout

      halt 200 if request.xhr?
      flash[:info] = 'Logged Out'
      redirect(::Ditty::Services::Settings[:logout_redirect_path] || "#{settings.map_path}/")
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
    post '/:provider/callback' do |provider|
      omniauth_callback provider
    end

    # Google OAuth login
    get '/:provider/callback' do |provider|
      omniauth_callback provider
    end
  end
end
