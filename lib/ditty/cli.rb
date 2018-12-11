# frozen_string_literal: true

# https://nandovieira.com/creating-generators-and-executables-with-thor
require 'dotenv/load'
require 'thor'
require 'ditty'
require 'ditty/rake_tasks'
require 'rack'
require 'rake'

module Ditty
  class CLI < Thor
    include Thor::Actions

    desc 'server', 'Start the Ditty server'
    require './application' if File.exist?('application.rb')
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
    end
  end
end
