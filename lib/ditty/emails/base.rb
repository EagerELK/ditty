require 'ditty/services/email'
require 'ditty/services/settings'
require 'ditty/components/app'

module Ditty
  module Emails
    class Base
      attr_accessor :view, :options, :locals

      def initialize(view, locals = {}, options = nil)
        @view = view
        @locals = locals
        @options = options ? options : base_options
      end

      def deliver(to = nil, locals = {})
        options[:to] = to unless to.nil?
        @locals.merge!(locals)
        %i[to from subject].each do |param|
          mail.send(param, options[param]) if options[param]
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

      def mail
        @mail ||= Services::Email.create
      end

      def content
        result = Haml::Engine.new(content_haml).render(Object.new, locals)
        return result unless options[:layout]
        Haml::Engine.new(layout_haml).render(Object.new, content: result)
      end

      def content_haml
        read_template(view)
      end

      def layout_haml
        read_template("layouts/#{options[:layout]}") if options[:layout]
      end

      def read_template(template)
        File.read(find_template("emails/#{template}"))
      end

      def base_options
        { subject: '(No Subject)', from: 'no-reply@ditty.io' }
      end

      def find_template(file)
        template = File.expand_path("./views/#{file}.haml")
        return template if File.file? template
        template = File.expand_path("./#{file}.haml", App.view_folder)
        return template if File.file? template
        file
      end

      class << self
        def deliver(to = nil, locals = {})
          new.deliver(to, locals)
        end
      end
    end
  end
end
