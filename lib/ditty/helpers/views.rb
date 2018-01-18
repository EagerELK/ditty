# frozen_string_literal: true

module Ditty
  module Helpers
    module Views
      def form_control(name, model, opts = {})
        label = opts.delete(:label) || name.to_s.titlecase
        klass = opts.delete(:class) || 'form-control' unless opts[:type] == 'file'
        group = opts.delete(:group) || model.class.to_s.demodulize.underscore
        field = opts.delete(:field) || name
        default = opts.delete(:default) || nil

        attributes = { type: 'text', id: name, name: "#{group}[#{name}]", class: klass }.merge(opts)
        haml :'partials/form_control', locals: {
          model: model,
          label: label,
          attributes: attributes,
          name: name,
          group: group,
          field: field,
          default: default
        }
      end

      def filter_control(filter, opts = {})
        meth = "#{filter[:name]}_options".to_sym
        return unless respond_to? meth
        haml :'partials/filter_control', locals: {
          name: filter[:name],
          label: opts[:label] || filter[:name].to_s.titlecase,
          options: send(meth)
        }
      end

      def flash_messages(key = :flash)
        return '' if flash(key).empty?
        id = (key == :flash ? 'flash' : "flash_#{key}")
        messages = flash(key).collect do |message|
          "  <div class='alert alert-#{message[0]} alert-dismissable' role='alert'>#{message[1]}</div>\n"
        end
        "<div id='#{id}'>\n" + messages.join + '</div>'
      end

      def delete_form(entity, label = 'Delete')
        locals = { delete_label: label, entity: entity }
        haml :'partials/delete_form', locals: locals
      end

      def query_string(add = {})
        qs = params.clone.merge(add)
        qs.delete('captures')
        Rack::Utils.build_query qs
      end

      def pagination(list, base_path, qp = {})
        return unless list.respond_to? :pagination_record_count
        locals = {
          first_link: "#{base_path}?" + query_string(qp.merge(page: 1)),
          next_link: list.last_page? ? '#' : "#{base_path}?" + query_string(qp.merge(page: list.next_page)),
          prev_link: list.first_page? ? '#' : "#{base_path}?" + query_string(qp.merge(page: list.prev_page)),
          last_link: "#{base_path}?" + query_string(qp.merge(page: list.page_count)),
          base_path: base_path,
          list: list
        }
        haml :'partials/pager', locals: locals
      end
    end
  end
end
