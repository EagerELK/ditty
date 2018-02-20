# frozen_string_literal: true

require 'ditty/controllers/component'
require 'ditty/models/user'
require 'ditty/policies/user_policy'
require 'ditty/models/identity'
require 'ditty/policies/identity_policy'

module Ditty
  class Users < Ditty::Component
    SEARCHABLE = %i[name surname email].freeze

    set model_class: User
    set track_actions: true

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Ditty
    end

    # New
    get '/new' do
      authorize settings.model_class, :create

      locals = {
        title: heading(:new),
        entity: User.new,
        identity: Identity.new
      }
      haml :"#{view_location}/new", locals: locals
    end

    # Create
    post '/' do
      authorize settings.model_class, :create

      locals = { title: heading(:new) }

      user_params = permitted_attributes(User, :create)
      identity_params = permitted_attributes(Identity, :create)
      user_params['email'] = identity_params['username']
      roles = user_params.delete('role_id')

      user     = locals[:user]     = User.new(user_params)
      identity = locals[:identity] = Identity.new(identity_params)

      DB.transaction(isolation: :serializable) do
        identity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect
        user.save
        user.add_identity identity
        if roles
          roles.each do |role_id|
            user.add_role(role_id) unless user.roles.map(&:id).include? role_id.to_i
          end
        end
        user.check_roles
      end

      log_action("#{dehumanized}_create".to_sym) if settings.track_actions
      create_response(user)
    end

    # Update
    put '/:id' do |id|
      entity = dataset.first(settings.model_class.primary_key => id)
      halt 404 unless entity
      authorize entity, :update

      values = permitted_attributes(settings.model_class, :update)
      roles  = values.delete('role_id')
      entity.set values
      entity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect

      if roles
        entity.remove_all_roles
        roles.each { |role_id| entity.add_role(role_id) }
        entity.check_roles
      end

      log_action("#{dehumanized}_update".to_sym) if settings.track_actions
      update_response(entity)
    end

    put '/:id/identity' do |id|
      entity = dataset.first(settings.model_class.primary_key => id)
      halt 404 unless entity
      authorize entity, :update

      identity = entity.identity.first
      identity_params = params['identity']

      unless identity_params['password'] == identity_params['password_confirmation']
        flash[:warning] = 'Password didn\'t match'
        return redirect back
      end

      unless current_user.super_admin? || identity.authenticate(identity_params['old_password'])
        log_action("#{dehumanized}_update_password_failed".to_sym) if settings.track_actions
        flash[:danger] = 'Old Password didn\'t match'
        return redirect back
      end

      values = permitted_attributes(Identity, :create)
      identity.set values
      if identity.valid? && identity.save
        log_action("#{dehumanized}_update_password".to_sym) if settings.track_actions
        flash[:success] = 'Password Updated'
        redirect back
      elsif current_user.super_admin? && current_user.id != id.to_i
        haml :"#{view_location}/display", locals: { entity: entity, identity: identity, title: heading }
      else
        haml :"#{view_location}/profile", locals: { entity: entity, identity: identity, title: heading }
      end
    end

    # Delete
    delete '/:id', provides: %i[html json] do |id|
      entity = dataset.first(settings.model_class.primary_key => id)
      halt 404 unless entity
      authorize entity, :delete

      entity.remove_all_identity
      entity.remove_all_roles
      entity.destroy

      log_action("#{dehumanized}_delete".to_sym) if settings.track_actions
      delete_response(entity)
    end

    # Profile
    get '/profile' do
      entity = current_user
      authorize entity, :read

      haml :"#{view_location}/profile", locals: { entity: entity, identity: entity.identity.first, title: 'My Account' }
    end
  end
end
