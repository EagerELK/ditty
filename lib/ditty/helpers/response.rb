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
                 locals: { list: result, title: heading(:list), actions: actions },
                 layout: layout
          end
          format.json do
            # TODO: Add links defined by actions (New #{heading})
            total = result.respond_to?(:pagination_record_count) ? result.pagination_record_count : result.count
            json(
              'items' => result.all.map(&:for_json),
              'page' => (params['page'] || 1).to_i,
              'count' => result.count,
              'total' => total
            )
          end
        end
      end

      def create_response(entity)
        respond_to do |format|
          format.html do
            flash[:success] = "#{heading} Created"
            redirect with_layout("#{base_path}/#{entity.id}")
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
            actions["#{base_path}/new"] = "New #{heading}" if policy(entity).create?
            title = heading(:read) + (entity.respond_to?(:name) ? ": #{entity.name}" : '')
            haml :"#{view_location}/display",
                 locals: { entity: entity, title: title, actions: actions },
                 layout: layout
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
            redirect with_layout("#{base_path}/#{entity.id}")
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
            redirect with_layout(base_path.to_s)
          end
          format.json do
            content_type :json
            headers 'Location' => base_path.to_s
            status 204
          end
        end
      end
    end
  end
end
