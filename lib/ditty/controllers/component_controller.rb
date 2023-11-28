# frozen_string_literal: true

require 'ditty/controllers/application_controller'
require 'ditty/helpers/component'
require 'ditty/helpers/response'
require 'sinatra/json'

module Ditty
  class ComponentController < ApplicationController
    use Rack::Csrf, raise: ENV['APP_ENV'] == 'development' unless ENV['APP_ENV'] == 'test'

    helpers Helpers::Component, Helpers::Response

    set base_path: nil
    set dehumanized: nil
    set view_location: nil
    set track_actions: false
    set heading: nil

    def read(id)
      dataset.with_pk(id)
    end

    def read!(id)
      halt 404 unless (entity = read(id))
      entity
    end

    def skip_verify!
      @skip_verify = true
    end

    def trigger(event, attribs = {})
      attribs[:target] ||= self
      send(event, attribs) if respond_to? event
      broadcast(event, attribs)
    end

    after do
      return if settings.environment == 'production'

      verify_authorized if (response.successful? || response.redirection?) && @skip_verify == false
    end

    after '/' do
      return if settings.environment == 'production' || request.request_method != 'GET'

      verify_policy_scoped if (response.successful? || response.redirection?) && @skip_verify == false
    end

    # List
    get '/' do
      authorize settings.model_class, :list

      result = list

      trigger :component_list

      list_response(result)
    end

    # Create Form
    get '/new/?' do
      authorize settings.model_class, :create

      entity = settings.model_class.new(permitted_parameters(settings.model_class, :create))
      haml :"#{view_location}/new",
           locals: { entity: entity, title: heading(:new), actions: actions(action: :new) },
           layout: layout
    end

    # Create
    post '/' do
      parameters = check_parameters(:create)
      entity = settings.model_class.new(parameters)
      authorize entity, :create

      entity.db.transaction do
        entity.save_changes # Will trigger a Sequel::ValidationFailed exception if the model is incorrect
        trigger :component_create, entity: entity
      end

      create_response(entity)
    end

    # Read
    get '/:id/?' do |id|
      entity = read!(id)
      authorize entity, :read

      trigger :component_read, entity: entity
      read_response(entity)
    end

    # Update Form
    get '/:id/edit/?' do |id|
      entity = read!(id)
      authorize entity, :update

      flash[:redirect_to] = "#{base_path}/#{entity.display_id}" unless flash.keep(:redirect_to)
      haml :"#{view_location}/edit",
           locals: { entity: entity, title: heading(:edit), actions: actions(entity: entity, action: :edit) },
           layout: layout
    end

    # Update
    put '/:id/?' do |id|
      entity = read!(id)
      authorize entity, :update
      parameters = check_parameters(:update)

      entity.db.transaction do
        entity.set(parameters)
        entity.save_changes # Will trigger a Sequel::ValidationFailed exception if the model is incorrect
        trigger :component_update, entity: entity
      end

      update_response(entity)
    end

    delete '/:id/?' do |id|
      entity = read!(id)
      authorize entity, :delete

      entity.db.transaction do
        entity.destroy
        trigger :component_delete, entity: entity
      end

      delete_response(entity)
    end
  end
end
