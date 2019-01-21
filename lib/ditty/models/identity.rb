# frozen_string_literal: true

require 'bcrypt'
require 'ditty/models/base'
require 'omniauth-identity'
require 'active_support'
require 'active_support/core_ext/object/blank'

module Ditty
  class Identity < ::Sequel::Model
    include ::Ditty::Base
    many_to_one :user

    attr_accessor :password, :password_confirmation

    # OmniAuth Related
    include OmniAuth::Identity::Model

    def self.locate(conditions)
      where(conditions).first
    end

    def authenticate(unencrypted)
      return false if crypted_password.blank?
      self if ::BCrypt::Password.new(crypted_password) == unencrypted
    end

    def persisted?
      !new? && @destroyed != true
    end

    # Return whatever we want to pass to the omniauth hash here
    def info
      {
        email: username
      }
    end

    # Validation
    def validate
      validates_presence :username
      unless username.blank?
        validates_unique :username
        validates_format(/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :username)
      end

      if password_required
        validates_presence :password
        validates_presence :password_confirmation
        validates_format(
          # 1 Uppercase
          # 1 lowercase
          # 1 Special Character
          # 1 Number
          # At least 8 characters
          %r[\A(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#&$*)(}{%^=_+|\\:";'<>,.\-\/?\[\]])(?=.*[0-9]).{8,}\Z],
          :password,
          message: 'is not strong enough'
        )
      end

      errors.add(:password_confirmation, 'must match password') if !password.blank? && password != password_confirmation
    end

    # Callbacks
    def before_save
      super
      encrypt_password unless password == '' || password.nil?
    end

    private

    def encrypt_password
      self.crypted_password = ::BCrypt::Password.create(password)
    end

    def password_required
      crypted_password.blank? || !password.blank?
    end
  end
end
