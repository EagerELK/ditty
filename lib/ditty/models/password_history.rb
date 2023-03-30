require 'ditty/models/base'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'securerandom'

module Ditty
  class PasswordHistory < ::Sequel::Model# frozen_string_literal: true
    include ::Ditty::Base
    many_to_one :identity

    def validate
      validates_presence [:crypted_password]
      validates_presence [:identity_id]
    end

    def before_save
      super
      self.id ||= SecureRandom.uuid
      self.created_at ||= Time.now
    end
  end
end
