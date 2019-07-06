# frozen_string_literal: true

require 'ditty/controllers/application_controller'
require 'ditty/helpers/component'
require 'ditty/helpers/response'
require 'sinatra/json'

module Ditty
  class ComponentController < ApplicationController
    helpers Helpers::Component, Helpers::Response

    set base_path: nil
    set dehumanized: nil
    set view_location: nil
    set track_actions: false
    set heading: nil

    def read(id)
      dataset.with_pk(id)
    end

    def skip_verify!
      @skip_verify = true
    end

    def trigger(event, attribs = {})
      attribs[:target] ||= self
      send(event, attribs) if self.respond_to? event
      broadcast(event, attribs)
    end

    after do
      return if settings.environment == 'production'

      if (response.successful? || response.redirection?) && @skip_verify == false
        verify_authorized if settings.environment != 'production'
      end
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

      entity = settings.model_class.new(permitted_attributes(settings.model_class, :create))
      session[:redirect_to] = request.fullpath
      haml :"#{view_location}/new",
           locals: { entity: entity, title: heading(:new) },
           layout: layout
    end

    # Create
    post '/' do
      entity = settings.model_class.new(permitted_attributes(settings.model_class, :create))
      authorize entity, :create

      entity.db.transaction do
        entity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect
        trigger :component_create, entity: entity
      end

      create_response(entity)
    end

    # Read
    get '/:id/?' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :read

      trigger :component_read, entity: entity
      read_response(entity)
    end

    # Update Form
    get '/:id/edit/?' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :update

      haml :"#{view_location}/edit",
           locals: { entity: entity, title: heading(:edit) },
           layout: layout
    end

    # Update
    put '/:id/?' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :update

      entity.db.transaction do
        entity.set(permitted_attributes(settings.model_class, :update))
        entity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect
        trigger :component_update, entity: entity
      end

      update_response(entity)
    end

    delete '/:id/?' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :delete

      entity.db.transaction do
        entity.destroy
        trigger :component_delete, entity: entity
      end

      delete_response(entity)
    end
  end
end
