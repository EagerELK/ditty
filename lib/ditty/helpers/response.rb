# frozen_string_literal: true

require 'csv'

module Ditty
  module Helpers
    module Response
      def list_response(result, view: 'index')
        actions = actions(action: :list)
        respond_to do |format|
          format.html do
            haml :"#{view_location}/#{view}",
                 locals: { list: result, title: heading(:list), actions: actions },
                 layout: layout
          end
          format.json do
            # TODO: Add links defined by actions (New #{heading})
            total = result.respond_to?(:pagination_record_count) ? result.pagination_record_count : result.count
            json(
              'items' => result.all.map { |e| permitted_response_attributes(e, :for_json) },
              'page' => (params['page'] || 1).to_i,
              'count' => result.count,
              'total' => total
            )
          end
          format.csv do
            attachment "#{base_path}.csv"
            CSV.generate do |csv|
              csv << result.first.for_csv.keys
              result.all.each do |r|
                csv << r.for_csv.values
              end
            end
          end
        end
      end

      def create_response(entity)
        respond_to do |format|
          format.html do
            flash[:success] = "#{heading} Created"
            redirect with_layout(params[:redirect_to] || flash[:redirect_to] || "#{base_path}/#{entity.display_id}")
          end
          format.json do
            content_type :json
            redirect "#{base_path}/#{entity.display_id}", 201
          end
        end
      end

      def actions(entity: nil, action: nil)
        actions = {}
        actions["#{base_path}/#{entity.display_id}/edit"] = "Edit #{heading}" if entity && policy(entity).update? && action != :edit
        actions[base_path] = "List #{heading(:list)}" if policy(entity || settings.model_class).list? && action != :list
        actions["#{base_path}/new"] = "New #{heading}" if policy(entity || settings.model_class).create? && action != :new
        actions
      end

      def read_response(entity)
        actions = actions(entity: entity, action: :read)
        respond_to do |format|
          format.html do
            title = heading(:read) + (entity.respond_to?(:name) ? ": #{entity.name}" : '')
            if settings.cache_headers && settings.html_cache_headers
              last_modified entity.updated_at if entity.respond_to?(:updated_at)
              etag entity.etag if entity.respond_to?(:etag)
            end
            haml :"#{view_location}/display",
                 locals: { entity: entity, title: title, actions: actions },
                 layout: layout
          end
          format.json do
            # TODO: Add links defined by actions (Edit #{heading})
            if settings.cache_headers && settings.json_cache_headers
              last_modified entity.updated_at if entity.respond_to?(:updated_at)
              etag entity.etag if entity.respond_to?(:etag)
            end
            json permitted_response_attributes(entity, :for_json)
          end
          format.csv do
            CSV.generate do |csv|
              csv << entity.for_csv.keys
              csv << entity.for_csv.values
            end
          end
        end
      end

      def update_response(entity)
        respond_to do |format|
          format.html do
            # TODO: Ability to customize the return path and message?
            flash[:success] = "#{heading} Updated"
            redirect with_layout(params[:redirect_to] || flash[:redirect_to] || "#{base_path}/#{entity.display_id}")
          end
          format.json do
            content_type :json
            redirect "#{base_path}/#{entity.display_id}", 200, json(entity.for_json)
          end
        end
      end

      def delete_response(_entity)
        respond_to do |format|
          format.html do
            flash[:success] = "#{heading} Deleted"
            redirect with_layout(params[:redirect_to] || flash[:redirect_to] || back || base_path)
          end
          format.json do
            content_type :json
            redirect base_path.to_s, 204
          end
        end
      end
    end
  end
end
