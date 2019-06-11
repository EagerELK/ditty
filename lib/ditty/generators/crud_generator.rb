# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'

module Ditty
  module Generators
    class CrudGenerator < Thor::Group
      include Thor::Actions
      attr_reader :namespace, :folder, :views_folder, :controller_name, :model_name, :policy_name # , :file_name

      desc 'Create a CRUD Endpoint including the Model, Controller, Policy and Views'
      argument :name, type: :string, desc: 'Name of the Model, eg. MyApp::User'

      # --no-views make views optional
      class_option :views, type: :boolean, default: true, desc: 'Generate views for controller'

      def self.source_root
        File.dirname(__FILE__)
      end

      def setup
        @namespace       = name.deconstantize
        @folder          = namespace.underscore
        @model_name      = name.demodulize
        @views_folder    = File.join('views', model_name.pluralize.underscore)
        @controller_name = "#{model_name.pluralize}Controller"
        @policy_name     = "#{model_name}Policy"
      end

      def create_model
        filename = File.join("lib/#{folder}/models", "#{model_name.underscore}.rb")
        template '../templates/model.rb.erb', filename
      end

      def create_controller
        filename = File.join("lib/#{folder}/controllers", "#{controller_name.underscore}.rb")
        template '../templates/controller.rb.erb', filename
        # TODO: Insert the route into the component file
        # insert_into_file 'config.ru', "use #{class_name}\n", after: 'run ApplicationController\n'
      end

      def create_policy
        filename = File.join("lib/#{folder}/policies", "#{policy_name.underscore}.rb")
        template '../templates/policy.rb.erb', filename
      end

      def create_views
        return unless options[:views]

        directory '../templates/views', views_folder
      end

      private

      def columns
        require "#{folder}/models/#{model_name.underscore}"
        name.constantize.columns - %i[id created_at updated_at]
      rescue StandardError
        []
      end

      def many_to_ones
        DB.foreign_key_list(model_name.underscore.pluralize)
      end

      def name_column(table)
        candidates = DB.schema(table.to_sym).to_h.keys - DB.foreign_key_list(table.to_sym).map { |e| e[:columns] }.flatten
        (candidates - %i[id slug]).first
      end
    end
  end
end
