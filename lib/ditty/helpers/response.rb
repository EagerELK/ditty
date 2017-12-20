# frozen_string_literal: true

module Ditty
  module Helpers
    module Response
      def list_response(result)
        respond_to do |format|
          format.html do
            actions = {}
            actions["#{base_path}/new"] = "New #{heading}" if policy(settings.model_class).create?
            haml :"#{view_location}/index",
                 locals: { list: result, title: heading(:list), actions: actions }
          end
          format.json do
            # TODO: Add links defined by actions (New #{heading})
            json(
              'items' => result.all.map(&:for_json),
              'page' => (params['page'] || 1).to_i,
              'count' => result.count,
              'total' => result.pagination_record_count
            )
          end
        end
      end

      def create_response(entity)
        respond_to do |format|
          format.html do
            flash[:success] = "#{heading} Created"
            redirect "#{base_path}/#{entity.id}"
          end
          format.json do
            content_type :json
            redirect "#{base_path}/#{entity.id}", 201
          end
        end
      end

      def read_response(entity)
        respond_to do |format|
          format.html do
            actions = {}
            actions["#{base_path}/#{entity.id}/edit"] = "Edit #{heading}" if policy(entity).update?
            title = heading(:read) + (entity.respond_to?(:name) ? ": #{entity.name}" : '')
            haml :"#{view_location}/display", locals: { entity: entity, title: title, actions: actions }
          end
          format.json do
            # TODO: Add links defined by actions (Edit #{heading})
            json entity.for_json
          end
        end
      end

      def update_response(entity)
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
      end

      def delete_response(_entity)
        respond_to do |format|
          format.html do
            flash[:success] = "#{heading} Deleted"
            redirect base_path.to_s
          end
          format.json do
            content_type :json
            headers 'Location' => "#{base_path}"
            status 204
          end
        end
      end
    end
  end
end
