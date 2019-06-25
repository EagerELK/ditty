# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'

module Ditty
  module Generators
    class ProjectGenerator < Thor::Group
      include Thor::Actions

      desc 'Initialize a new Ditty project in the current folder'

      def self.source_root
        File.expand_path('../templates', __dir__)
      end

      def create_startup_files
        copy_file 'config.ru', './config.ru'
        copy_file 'application.rb', './application.rb'
        copy_file 'Rakefile', './Rakefile'
        copy_file '.gitignore', './.gitignore'
        copy_file 'env.example', './.env'
        copy_file 'sidekiq.rb', './config/sidekiq.rb'
        copy_file 'sidekiq.yml', './config/sidekiq.yml'
        copy_file 'settings.yml', './config/settings.yml'
        copy_file 'spec_helper.rb', './specs/spec_helper.rb'
        copy_file '../../../spec/support/api_shared_examples.rb', './specs/support/api_shared_examples.rb'
        copy_file '../../../spec/support/crud_shared_examples.rb', './specs/support/crud_shared_examples.rb'
        directory 'logs'
        directory 'pids'
        # spec/support/api_shared_examples
        # spec/support/crud_shared_examples
      end

      # def create_controller
      #   filename = File.join("lib/#{folder}/controllers", "#{controller_name.underscore}.rb")
      #   template '../templates/controller.rb.erb', filename
      #   # TODO: Insert the route into the component file
      #   # insert_into_file 'config.ru', "use #{class_name}\n", after: 'run ApplicationController\n'
      # end

      # def create_policy
      #   filename = File.join("lib/#{folder}/policies", "#{policy_name.underscore}.rb")
      #   template '../templates/policy.rb.erb', filename
      # end

      # def create_views
      #   return unless options[:views]

      #   directory '../templates/views', views_folder
      # end
    end
  end
end
