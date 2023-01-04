# frozen_string_literal: true

# https://nandovieira.com/creating-generators-and-executables-with-thor
require 'dotenv/load' rescue LoadError # rubocop:disable Style/RescueModifier - Ignore dotenv/load errors
require 'thor'
require 'rack'
require 'rake'
require 'ditty/db' if ENV['DATABASE_URL']
require 'ditty/generators/crud_generator'
require 'ditty/generators/project_generator'
require 'ditty/generators/migration_generator'
require 'ditty/components/ditty'

# TODO: Component generator
# TODO: Add requires into application.rb
# TODO: Add requires into schema.rb

module Ditty
  class CLI < Thor
    include Thor::Actions

    register ::Ditty::Generators::CrudGenerator, 'crud', 'crud NAME', 'Generate a CRUD endpoint'

    register ::Ditty::Generators::ProjectGenerator, 'init', 'init', 'Initialize a Ditty Project'

    register ::Ditty::Generators::MigrationGenerator, 'migration', 'migration NAME', 'Create a new Sequel migration'

    default_task :server

    desc 'server', 'Start the Ditty server'
    require './application' if File.exist?('application.rb')
    require 'ditty/db' unless defined?(DB)
    ::Ditty::Components.tasks

    def server
      # Ensure the token files are present
      Rake::Task['ditty:generate_tokens'].invoke

      # Prep Ditty
      Rake::Task['ditty:prep:folders'].invoke
      Rake::Task['ditty:prep:migrations'].invoke

      # Check the migrations
      Rake::Task['ditty:migrate:check'].invoke

      # Seed Ditty DB
      puts 'Seeding the Ditty DB'
      Rake::Task['ditty:seed'].invoke

      # RackUP!
      rack_opts = {
        environment: ENV['APP_ENV'] || 'development',
        Port: ENV['APP_PORT'] || 9292,
        Host: ENV['APP_HOST'] || '0.0.0.0',
        config: "config.ru"
      }
      puts 'Starting the Ditty Server'
      Rack::Server.start(rack_opts)
    end

    desc 'migrate', 'Run the Ditty migrations'
    def migrate
      # Prep Ditty
      Rake::Task['ditty:prep:migrations'].invoke

      # Run the migrations
      Rake::Task['ditty:migrate:up'].invoke
      puts 'Ditty Migrations Executed'

      Rake::Task['ditty:dump_schema'].invoke
      puts 'Ditty DB Schema Dumped'
    end

    desc 'seed', 'Seed the predefined seeding data'
    def seed
      Rake::Task['ditty:seed'].invoke
    end

    desc 'console', 'Open a fully loaded console'
    def console
      Rake::Task['ditty:console'].invoke
    end
  end
end
