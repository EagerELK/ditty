# frozen_string_literal: true

require 'ditty/services/pagination_wrapper'

module Ditty
  module Helpers
    module Views
      def layout
        return :embedded if request.params['layout'] == 'embedded'

        :layout
      end

      def with_layout(url)
        uri = URI.parse(url)
        # Don't set the layout if there's none. Don't set the layout for external URIs
        return url if params['layout'].nil? || uri.host

        qs = { 'layout' => params['layout'] }.merge(uri.query ? CGI.parse(uri.query) : {})
        uri.query = Rack::Utils.build_query qs
        uri.to_s
      end

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

      def query_string(add = {})
        qs = params.clone.merge(add)
        qs.delete('captures')
        Rack::Utils.build_query qs
      end

      def delete_form(entity, label = 'Delete')
        locals = { delete_label: label, entity: entity }
        haml :'partials/delete_form', locals: locals
      end

      def delete_form_tag(url, options = {}, &block)
        options[:form_verb] = :delete
        form_tag(url, options, &block)
      end

      def edit_form_tag(url, options = {}, &block)
        options[:form_verb] = :put
        form_tag(url, options, &block)
      end

      def new_form_tag(url, options = {}, &block)
        options[:form_verb] = :post
        form_tag(url, options, &block)
      end

      def form_tag(url, options = {}, &block)
        options[:form_verb] ||= :post
        options[:attributes] ||= {}
        options[:attributes] = { 'class': 'form-horizontal' }.merge options[:attributes]
        options[:url] = options[:form_verb].to_sym == :get ? url : with_layout(url)
        haml :'partials/form_tag', locals: options.merge(block: block)
      end

      def pagination(list, base_path, qp = {})
        return unless list.respond_to?(:pagination_record_count) || list.respond_to?(:total_entries)

        list = Ditty::Services::PaginationWrapper.new(list)
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

      def display(value, type = :string)
        if [true, false].include?(value) || type.to_sym == :boolean
          value ? 'Yes' : 'No'
        elsif value.nil? || type.to_sym == :nil
          '(Empty)'
        else
          value
        end
      end

      def url_for(options = nil)
        return options if options.is_a? String
        return request.env['HTTP_REFERER'] if options == :back && request.env['HTTP_REFERER']

        raise 'Unimplemented'
      end

      def link_to(name = nil, options = nil, html_options = {})
        html_options[:href] ||= url_for(options)

        capture_haml do
          haml_tag :a, name, html_options
        end
      end
    end
  end
end
