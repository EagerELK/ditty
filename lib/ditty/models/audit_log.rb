# frozen_string_literal: true

require 'ditty/models/base'

module Ditty
  class AuditLog < ::Sequel::Model
    include ::Ditty::Base
    many_to_one :user

    def validate
      super
      validates_presence [:action]
    end
  end
end
