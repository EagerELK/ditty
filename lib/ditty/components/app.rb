# frozen_string_literal: true

require 'ditty'
require 'ditty/services/settings'

module Ditty
  class App
    def self.load
      controllers = File.expand_path('../controllers', __dir__)
      Dir.glob("#{controllers}/*.rb").each { |f| require f }

      require 'ditty/models/user'
      require 'ditty/models/role'
      require 'ditty/models/identity'
      require 'ditty/models/audit_log'
    end

    def self.configure(_container)
      require 'ditty/db' unless defined? ::DB
      require 'ditty/listener'
    end

    def self.migrations
      File.expand_path('../../../migrate', __dir__)
    end

    def self.view_folder
      File.expand_path('../../../views', __dir__)
    end

    def self.routes
      load
      {
        '/' => ::Ditty::Main,
        '/auth' => ::Ditty::Auth,
        '/users' => ::Ditty::Users,
        '/roles' => ::Ditty::Roles,
        '/audit-logs' => ::Ditty::AuditLogs
      }
    end

    def self.navigation
      load

      [
        {
          group: 'User Management',
          order: 10,
          icon: 'lock',
          target: ::Ditty::User,
          items: [
            { order: 10, link: '/users/', text: 'Users', target: ::Ditty::User, icon: 'user' },
            { order: 20, link: '/roles/', text: 'Roles', target: ::Ditty::Role, icon: 'check-square' },
            { order: 30, link: '/audit-logs/', text: 'Audit Logs', target: ::Ditty::AuditLog, icon: 'history' }
          ]
        }
      ]
    end

    def self.seeder
      proc do
        load

        ::Ditty::Role.find_or_create(name: 'super_admin')
        ::Ditty::Role.find_or_create(name: 'admin')
        ::Ditty::Role.find_or_create(name: 'user')
      end
    end

    def self.tasks
      Kernel.load 'ditty/tasks/ditty.rake'
      Kernel.load 'ditty/tasks/omniauth-ldap.rake' if Ditty::Services::Settings[:authentication].keys.include? :ldap
    end
  end
end

Ditty::Components.register_component(:app, Ditty::App)
