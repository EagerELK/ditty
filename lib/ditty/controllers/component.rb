# frozen_string_literal: true

require 'ditty/controllers/application'
require 'ditty/helpers/component'
require 'ditty/helpers/response'
require 'sinatra/json'

module Ditty
  class Component < Application
    helpers Helpers::Component, Helpers::Response

    set base_path: nil
    set dehumanized: nil
    set view_location: nil
    set track_actions: false

    def read(id)
      dataset.first(settings.model_class.primary_key => id)
    end

    after do
      verify_authorized unless settings.environment == 'production'
    end

    after '/' do
      verify_policy_scoped unless settings.environment == 'production'
    end

    # List
    get '/' do
      authorize settings.model_class, :list

      result = list

      log_action("#{dehumanized}_list".to_sym) if settings.track_actions
      list_response(result)
    end

    # Create Form
    get '/new' do
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

      entity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect

      log_action("#{dehumanized}_create".to_sym) if settings.track_actions
      create_response(entity)
    end

    # Read
    get '/:id' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :read

      log_action("#{dehumanized}_read".to_sym) if settings.track_actions
      read_response(entity)
    end

    # Update Form
    get '/:id/edit' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :update

      haml :"#{view_location}/edit",
           locals: { entity: entity, title: heading(:edit) },
           layout: layout
    end

    # Update
    put '/:id' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :update

      entity.set(permitted_attributes(settings.model_class, :update))
      entity.save # Will trigger a Sequel::ValidationFailed exception if the model is incorrect

      log_action("#{dehumanized}_update".to_sym) if settings.track_actions
      update_response(entity)
    end

    delete '/:id' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :delete

      entity.destroy

      log_action("#{dehumanized}_delete".to_sym) if settings.track_actions
      delete_response(entity)
    end
  end
end
