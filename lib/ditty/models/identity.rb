# frozen_string_literal: true

require 'bcrypt'
require 'ditty/models/base'
require 'ditty/models/password_history'
require 'omniauth-identity'
require 'active_support'
require 'active_support/core_ext/object/blank'

module Ditty
  class Identity < ::Sequel::Model
    include ::Ditty::Base
    many_to_one :user
    one_to_many :password_histories

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

    def uid
      user&.id
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
          %r[\A(?=.*[A-Z])(?=.*[a-z])(?=.*[!@#&$*)(}{%^=_+|\\:";'<>,.\-\/?\[\]])(?=.*[0-9]).+\Z],
          :password,
          message: 'must contain at least one number, one uppercase, one lowercase and one special character'
        )
        validates_min_length(
          min_password_length,
          :password,
          message: "must be at least #{min_password_length} characters",
        )
      end

      errors.add(:password_confirmation, 'must match password') if !password.blank? && password != password_confirmation
      errors.add(:password, 'must not be a password you have used before') if !password.blank? && validate_used_passwords

    end

    def validate_used_passwords
      used_passwords = password_histories.map { |ph| BCrypt::Password.new(ph.crypted_password)}
      used_passwords.include?(password)
    end

    def min_password_length
      Ditty::Services::Authentication.config.dig(:identity, :min_password_length) || 8
    end

    # Callbacks
    def before_save
      super
      encrypt_password unless password == '' || password.nil?
    end

    def after_save
      super

      PasswordHistory.create({ identity_id: self.id, crypted_password: self.crypted_password }) if !password.blank?
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
