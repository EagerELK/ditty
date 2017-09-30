# frozen_string_literal: true

module Ditty
  class App
    def self.migrations
      File.expand_path('../../../../migrate', __FILE__)
    end

    def self.view_folder
      File.expand_path('../../../../views', __FILE__)
    end

    def self.routes
      controllers = File.expand_path('../app/controllers', __FILE__)
      Dir.glob("#{controllers}/*.rb").each { |f| require f }
      {
        '/' => ::Ditty::Main,
        '/users' => ::Ditty::Users,
        '/roles' => ::Ditty::Roles,
        '/audit-logs' => ::Ditty::AuditLogs
      }
    end

    def self.navigation
      require 'ditty/components/app/models/user'
      require 'ditty/components/app/models/role'
      require 'ditty/components/app/models/audit_log'

      [
        {
          group: 'User Management',
          order: 10,
          icon: 'lock',
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
        require 'ditty/components/app/models/user'
        require 'ditty/components/app/models/role'

        ::Ditty::Role.find_or_create(name: 'super_admin')
        ::Ditty::Role.find_or_create(name: 'admin')
        user_role = ::Ditty::Role.find_or_create(name: 'user')

        # Anonymous User
        anon = ::Ditty::User.find_or_create(email: 'anonymous@ditty.io')
        anon.remove_role user_role
        anon_role = ::Ditty::Role.find_or_create(name: 'anonymous')
        anon.add_role anon_role unless anon.role?('anonymous')
      end
    end
  end
end

Ditty::Components.register_component(:app, Ditty::App)
Ditty.component :app
