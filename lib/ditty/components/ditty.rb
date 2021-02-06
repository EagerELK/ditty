# frozen_string_literal: true

require 'ditty'
require 'ditty/services/settings'

module Ditty
  class Ditty
    def self.load
      controllers = File.expand_path('../controllers', __dir__)
      Dir.glob("#{controllers}/*.rb").sort.each { |f| require f }

      require 'ditty/models/user'
      require 'ditty/models/role'
      require 'ditty/models/identity'
      require 'ditty/models/audit_log'
      require 'ditty/models/user_login_trait'
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
        '/' => ::Ditty::MainController,
        '/auth' => ::Ditty::AuthController,
        '/users' => ::Ditty::UsersController,
        '/roles' => ::Ditty::RolesController,
        '/audit-logs' => ::Ditty::AuditLogsController,
        '/login-traits' => ::Ditty::UserLoginTraitsController
      }
    end

    def self.navigation
      load

      [
        {
          group: 'User Management',
          order: 50,
          icon: 'lock',
          target: ::Ditty::User,
          items: [
            { order: 10, link: '/users/', text: 'Users', target: ::Ditty::User, icon: 'user' },
            { order: 20, link: '/roles/', text: 'Roles', target: ::Ditty::Role, icon: 'check-square' },
            { order: 30, link: '/audit-logs/', text: 'Audit Logs', target: ::Ditty::AuditLog, icon: 'history' },
            { order: 40, link: '/login-traits/', text: 'User Login Traits', target: ::Ditty::UserLoginTrait,
              icon: 'list' }
          ]
        }
      ]
    end

    def self.seeder
      proc do
        load

        sa = ::Ditty::Role.find_or_create(name: 'super_admin')
        admin = ::Ditty::Role.find_or_create(name: 'admin') { |e| e.parent = sa }
        ::Ditty::Role.find_or_create(name: 'user') { |e| e.parent = admin }
      end
    end

    def self.tasks
      Kernel.load 'ditty/tasks/ditty.rake'
      auth_settings = ::Ditty::Services::Settings[:authentication] || {}
      Kernel.load 'ditty/tasks/omniauth-ldap.rake' if auth_settings.key?(:ldap)
    end
  end
end

Ditty::Components.register_component(:ditty, Ditty::Ditty)
