# frozen_string_literal: true

require 'thor/group'
require 'active_support/inflector'

module Ditty
  module Generators
    class ProjectGenerator < Thor::Group
      include Thor::Actions

      attr_reader :name, :namespace, :folder

      desc 'Initialize a new Ditty project in the current folder'

      def setup
        @name      = File.basename(Dir.getwd)
        @folder    = @name.underscore
        @namespace = folder.classify
        @name      = @name.titleize
      end

      def self.source_root
        File.expand_path('../templates', __dir__)
      end

      def create_startup_files
        directory 'logs'
        directory 'pids'
        directory 'public'
        directory '../../../views', 'views'
        copy_file '.gitignore', './.gitignore'
        copy_file 'env.example', './.env'
        copy_file '.rubocop.yml', './.rubocop.yml'
        copy_file '.rspec', './.rspec'

        template 'lib/project.rb.erb', "lib/#{folder}.rb"

        copy_file 'application.rb', './application.rb'
        copy_file 'config.ru', './config.ru'
        copy_file 'Rakefile', './Rakefile'
        copy_file 'sidekiq.rb', './config/sidekiq.rb'
        copy_file 'sidekiq.yml', './config/sidekiq.yml'

        copy_file 'spec_helper.rb', './spec/spec_helper.rb'
        copy_file '../../../spec/support/api_shared_examples.rb', './spec/support/api_shared_examples.rb'
        copy_file '../../../spec/support/crud_shared_examples.rb', './spec/support/crud_shared_examples.rb'

        template 'settings.yml.erb', './config/settings.yml'
      end
    end
  end
end
