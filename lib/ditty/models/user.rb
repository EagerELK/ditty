# frozen_string_literal: true

require 'ditty/models/base'
require 'digest/md5'
require 'active_support'
require 'active_support/core_ext/object/blank'

# Why not store this in Elasticsearch?
module Ditty
  class User < ::Sequel::Model
    include ::Ditty::Base

    one_to_many :identity
    many_to_many :roles
    one_to_many :audit_logs

    def role?(check)
      @roles ||= Hash.new do |h, k|
        h[k] = !roles_dataset.first(name: k).nil?
      end
      @roles[check]
    end

    def method_missing(method_sym, *arguments, &block)
      if respond_to_missing?(method_sym)
        role?(method_sym[0..-2])
      else
        super
      end
    end

    def respond_to_missing?(name, _include_private = false)
      name[-1] == '?'
    end

    def gravatar
      hash = Digest::MD5.hexdigest(email.downcase)
      "https://www.gravatar.com/avatar/#{hash}"
    end

    def validate
      validates_presence :email
      return if email.blank?
      validates_unique :email
      validates_format(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :email)
    end

    # Add the basic roles and identity
    def after_create
      check_roles
    end

    def check_roles
      return if roles_dataset.first(name: 'anonymous')
      return if roles_dataset.first(name: 'user')
      add_role Role.find_or_create(name: 'user')
    end

    def username
      identity_dataset.first.username
    end
  end
end
