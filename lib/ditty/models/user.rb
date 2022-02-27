# frozen_string_literal: true

require 'ditty/models/base'
require 'digest/md5'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'ditty/models/role'

# Why not store this in Elasticsearch?
module Ditty
  class User < ::Sequel::Model
    include ::Ditty::Base

    one_to_many :identity
    many_to_many :roles
    one_to_many :audit_logs
    one_to_many :user_login_traits

    def role?(check)
      @roles ||= Hash.new do |h, k|
        role_or_descendant = roles.find do |role|
          role.name == k || role.descendants.map(&:name).include?(k)
        end
        h[k] = !role_or_descendant.nil?
      end
      @roles[check]
    end

    def all_roles
      roles.inject([]) do |memo, role|
        memo + [role] + role.descendants
      end.uniq
    end

    def method_missing(method_sym, *arguments, &block)
      if respond_to_missing?(method_sym)
        role?(method_sym[0..-2])
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private = false)
      return true if name[-1] == '?'

      super
    end

    def gravatar
      hash = Digest::MD5.hexdigest(email.downcase)
      "https://www.gravatar.com/avatar/#{hash}"
    end

    def validate
      super
      validates_presence :email
      return if email.blank?

      validates_unique :email
      validates_format(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :email)
    end

    def before_save
      super
      self.name = nil if name.blank?
      self.surname = nil if surname.blank?
    end

    # Add the basic roles and identity
    def after_create
      super
      check_roles
    end

    def check_roles
      return if roles_dataset.first(name: 'anonymous')
      return if roles_dataset.first(name: 'user')

      add_role Role.find_or_create(name: 'user')
    end

    def username
      identity = identity_dataset.first
      return identity.username if identity

      email
    end

    def display_name
      name || username
    end
  end
end
