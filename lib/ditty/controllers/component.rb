# frozen_string_literal: true

require 'ditty/controllers/application'
require 'ditty/helpers/component'
require 'sinatra/json'

module Ditty
  class Component < Application
    helpers Helpers::Component

    set base_path: nil
    set dehumanized: nil
    set view_location: nil
    set track_actions: false

    def read(id)
      dataset.first(settings.model_class.primary_key => id)
    end

    # List
    get '/', provides: %i[html json] do
      authorize settings.model_class, :list

      actions = {}
      actions["#{base_path}/new"] = "New #{heading}" if policy(settings.model_class).create?

      log_action("#{dehumanized}_list".to_sym) if settings.track_actions
      respond_to do |format|
        format.html do
          haml :"#{view_location}/index",
               locals: { list: list, title: heading(:list), actions: actions }
        end
        format.json do
          # TODO: Add links defined by actions (New #{heading})
          json(
            'items' => list.all.map(&:for_json),
            'page' => (params['page'] || 1).to_i,
            'count' => list.count,
            'total' => dataset.count
          )
        end
      end
    end

    # Create Form
    get '/new' do
      authorize settings.model_class, :create

      entity = settings.model_class.new(permitted_attributes(settings.model_class, :create))
      haml :"#{view_location}/new", locals: { entity: entity, title: heading(:new) }
    end

    # Create
    post '/' do
      entity = settings.model_class.new(permitted_attributes(settings.model_class, :create))
      authorize entity, :create
      success = entity.valid? && entity.save

      log_action("#{dehumanized}_create".to_sym) if success && settings.track_actions
      respond_to do |format|
        format.html do
          if success
            flash[:success] = "#{heading} Created"
            redirect "#{base_path}/#{entity.id}"
          else
            haml :"#{view_location}/new", locals: { entity: entity, title: heading(:new) }
          end
        end
        format.json do
          content_type :json
          if success
            redirect "#{base_path}/#{entity.id}", 201
          else
            [400, { errors: entity.errors }.to_json]
          end
        end
      end
    end

    # Read
    get '/:id' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :read

      actions = {}
      actions["#{base_path}/#{entity.id}/edit"] = "Edit #{heading}" if policy(entity).update?

      log_action("#{dehumanized}_read".to_sym) if settings.track_actions
      respond_to do |format|
        format.html do
          title = heading(:read) + (entity.respond_to?(:name) ? ": #{entity.name}" : '')
          haml :"#{view_location}/display", locals: { entity: entity, title: title, actions: actions }
        end
        format.json do
          # TODO: Add links defined by actions (Edit #{heading})
          json entity.for_json
        end
      end
    end

    # Update Form
    get '/:id/edit' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :update

      haml :"#{view_location}/edit", locals: { entity: entity, title: heading(:edit) }
    end

    # Update
    put '/:id' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :update

      entity.set(permitted_attributes(settings.model_class, :update))

      success = entity.valid? && entity.save
      log_action("#{dehumanized}_update".to_sym) if success && settings.track_actions
      if success
        respond_to do |format|
          format.html do
            # TODO: Ability to customize the return path and message?
            flash[:success] = "#{heading} Updated"
            redirect "#{base_path}/#{entity.id}"
          end
          format.json do
            headers 'Location' => "#{base_path}/#{entity.id}"
            json body entity.for_json
          end
        end
      else
        respond_to do |format|
          format.html do
            haml :"#{view_location}/edit", locals: { entity: entity, title: heading(:edit) }
          end
          format.json do
            content_type :json
            [400, { errors: entity.errors }.to_json]
          end
        end
      end
    end

    delete '/:id' do |id|
      entity = read(id)
      halt 404 unless entity
      authorize entity, :delete

      entity.destroy

      log_action("#{dehumanized}_delete".to_sym) if settings.track_actions
      respond_to do |format|
        format.html do
          flash[:success] = "#{heading} Deleted"
          redirect base_path.to_s
        end
        format.json do
          content_type :json
          headers 'Location' => '/users'
          status 204
        end
      end
    end
  end
end
