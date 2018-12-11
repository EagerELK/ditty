# frozen_string_literal: true

require 'haml'
require 'ditty/components/app'

module Ditty
  module Emails
    class Base
      attr_accessor :options, :locals, :mail

      def initialize(options = {})
        @mail = options[:mail] || Mail.new
        @locals = options[:locals] || {}
        @options = base_options.merge options
      end

      def deliver!(to = nil, locals = {})
        options[:to] = to unless to.nil?
        @locals.merge!(locals)
        %i[to from subject content_type].each do |param|
          next unless options[param]

          @locals[param] ||= options[param]
          mail.send(param, options[param])
        end
        mail.body content
        mail.deliver!
      end

      def method_missing(method, *args, &block)
        return super unless respond_to_missing?(method)

        mail.send(method, *args, &block)
      end

      def respond_to_missing?(method, _include_private = false)
        mail.respond_to? method
      end

      private

      def content
        result = Haml::Engine.new(content_haml).render(Object.new, locals)
        return result unless options[:layout]

        Haml::Engine.new(layout_haml).render(Object.new, locals.merge(content: result))
      end

      def content_haml
        read_template(options[:view])
      end

      def layout_haml
        read_template("layouts/#{options[:layout]}") if options[:layout]
      end

      def read_template(template)
        File.read(find_template("emails/#{template}"))
      end

      def base_options
        { subject: '(No Subject)', from: 'no-reply@ditty.io', view: :base, content_type: 'text/html; charset=UTF-8' }
      end

      def find_template(file)
        template = File.expand_path("./views/#{file}.haml")
        return template if File.file? template

        template = File.expand_path("./#{file}.haml", App.view_folder)
        return template if File.file? template

        file
      end

      class << self
        def deliver!(to = nil, options = {})
          locals = options[:locals] || {}
          new(options).deliver!(to, locals)
        end
      end
    end
  end
end
