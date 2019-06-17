# frozen_string_literal: true

# https://nandovieira.com/creating-generators-and-executables-with-thor
require 'dotenv/load' rescue LoadError # rubocop:disable Style/RescueModifier - Ignore dotenv/load errors
require 'thor'
require 'rack'
require 'rake'
require 'ditty/db' if ENV['DATABASE_URL']
require 'ditty/generators/crud_generator'
require 'ditty/components/app'

module Ditty
  class CLI < Thor
    include Thor::Actions

    register Ditty::Generators::CrudGenerator, 'crud', 'crud NAME', 'Generate a CRUD endpoint'

    desc 'server', 'Start the Ditty server'
    require './application' if File.exist?('application.rb')
    Ditty::Components.tasks
    def server
      # Ensure the token files are present
      Rake::Task['ditty:generate_tokens'].invoke

      # Prep Ditty
      Rake::Task['ditty:prep'].invoke

      # Check the migrations
      Rake::Task['ditty:migrate:check'].invoke

      # Seed Ditty DB
      puts 'Seeding the Ditty DB'
      Rake::Task['ditty:seed'].invoke

      # RackUP!
      puts 'Starting the Ditty Server'
      Rack::Server.start(config: 'config.ru')
    end

    desc 'migrate', 'Run the Ditty migrations'
    def migrate
      # Prep Ditty
      Rake::Task['ditty:prep'].invoke

      # Run the migrations
      Rake::Task['ditty:migrate:up'].invoke
      puts 'Ditty Migrations Executed'

      Rake::Task['ditty:dump_schema'].invoke
      puts 'Ditty DB Schema Dumped'
    end

    desc 'console', 'Open a fully loaded console'
    def console
      Rake::Task['ditty:console'].invoke
    end
  end
end
