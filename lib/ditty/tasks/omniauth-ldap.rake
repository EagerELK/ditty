# frozen_string_literal: true

namespace :ditty do
  namespace :ldap do
    desc 'Check the LDAP settings'
    task :check do
      settings = Ditty::Services::Settings[:authentication][:ldap][:arguments].first
      ldap = Net::LDAP.new host: settings[:host], port: settings[:port]
      ldap.authenticate settings[:bind_dn], settings[:password] if settings[:bind_dn]
      raise 'Could not bind to LDAP server' unless ldap.bind

      puts 'LDAP Binding Successful'
    end

    desc 'Add the AD / LDAP Groups to Ditty as Roles'
    task :populate_groups, [:filter] do |_task, args|
      puts 'Adding AD / LDAP Groups to Ditty as Roles'
      require 'ditty/services/settings'
      require 'ditty/models/role'

      settings = Ditty::Services::Settings[:authentication][:ldap][:arguments].first
      ldap = Net::LDAP.new host: settings[:host], port: settings[:port]
      ldap.authenticate settings[:bind_dn], settings[:password] if settings[:bind_dn]
      if ldap.bind
        group_filter = Net::LDAP::Filter.construct(settings[:group_filter]) unless settings[:group_filter].blank?
        group_filter ||= Net::LDAP::Filter.eq('ObjectClass', 'Group')
        if args[:filter]
          search_filter = Net::LDAP::Filter.eq(*args[:filter].split(':', 2))
          filter = Net::LDAP::Filter.join(group_filter, search_filter)
        else
          filter = group_filter
        end
        ldap.search(base: settings[:base], filter: filter).each do |group|
          Ditty::Role.find_or_create(name: group.name) do |role|
            puts "Adding #{role.name}"
          end
        end
      else
        puts 'Could not connect to LDAP Server'
      end
    end
  end
end
