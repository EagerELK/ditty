# frozen_string_literal: true

require 'ditty/controllers/component_controller'
require 'ditty/models/user'
require 'ditty/models/user_login_trait'
require 'ditty/policies/user_policy'
require 'ditty/models/identity'
require 'ditty/policies/identity_policy'

module Ditty
  class UsersController < ::Ditty::ComponentController
    SEARCHABLE = %i[name surname email].freeze

    set model_class: User
    set track_actions: true

    # New
    get '/new/?' do
      authorize settings.model_class, :create

      locals = { title: heading(:new), entity: User.new, identity: Identity.new, actions: actions(action: :new) }
      haml :"#{view_location}/new", locals: locals
    end

    # Create
    post '/' do
      authorize settings.model_class, :create

      locals = { title: heading(:new) }

      user_params = permitted_parameters(User, :create)
      identity_params = permitted_parameters(Identity, :create)
      user_params['email'] = identity_params['username']
      roles = user_params.delete('role_id')

      user     = locals[:user]     = User.new(user_params)
      identity = locals[:identity] = Identity.new(identity_params)

      DB.transaction(isolation: :serializable) do
        begin
          identity.save_changes
        rescue Sequel::ValidationFailed
          raise unless request.accept? 'text/html'

          status 400
          locals = { title: heading(:new), entity: user, identity: identity }
          return haml(:"#{view_location}/new", locals: locals)
        end
        user.save_changes
        user.add_identity identity

        roles&.each do |role_id|
          user.add_role(role_id) unless user.roles.map(&:id).include? role_id.to_i
        end
        user.check_roles
      end

      broadcast(:component_create, target: self, entity: user)
      create_response(user)
    end

    # Update
    put '/:id/?' do |id|
      entity = dataset.first(settings.model_class.primary_key => id)
      halt 404 unless entity
      authorize entity, :update

      values = permitted_parameters(settings.model_class, :update)
      roles  = values.delete('role_id')
      entity.set values
      entity.save_changes # Will trigger a Sequel::ValidationFailed exception if the model is incorrect

      if roles
        entity.remove_all_roles
        roles.each { |role_id| entity.add_role(role_id) }
        entity.check_roles
      end

      broadcast(:component_update, target: self)
      update_response(entity)
    end

    put '/:id/identity/?' do |id|
      entity = dataset.first(settings.model_class.primary_key => id)
      halt 404 unless entity
      authorize entity, :update

      identity = entity.identity.first
      identity_params = params['identity']

      if (current_user.super_admin? == false || current_user_id == entity.id) && identity.authenticate(identity_params['old_password']) == false
        broadcast(:identity_update_password_failed, target: self)
        flash[:danger] = 'Old Password didn\'t match'
        return redirect(with_layout(params[:redirect_to] || flash[:redirect_to] || back))
      end

      values = permitted_parameters(Identity, :update)
      identity.set values
      if identity.valid?
        identity.save_changes
        broadcast(:identity_update_password, target: self)
        flash[:success] = 'Password Updated'
        redirect back
      elsif current_user.super_admin? && current_user.id != id.to_i
        broadcast(:identity_update_password_failed, target: self)
        haml :"#{view_location}/display", locals: { entity: entity, identity: identity, title: heading }
      else
        broadcast(:identity_update_password_failed, target: self)
        haml :"#{view_location}/profile", locals: { entity: entity, identity: identity, title: heading }
      end
    end

    # Delete
    delete '/:id/?', provides: %i[html json] do |id|
      entity = dataset.first(settings.model_class.primary_key => id)
      halt 404 unless entity
      authorize entity, :delete

      entity.remove_all_identity
      entity.remove_all_roles
      entity.destroy

      broadcast(:component_delete, target: self)
      delete_response(entity)
    end

    # Profile
    get '/profile/?' do
      entity = current_user
      halt 404 unless entity
      authorize entity, :read

      flash[:redirect_to] = request.path
      haml :"#{view_location}/profile", locals: { entity: entity, identity: entity.identity.first, title: 'My Account', actions: actions(entity: entity, action: :read) }
    end
  end
end
