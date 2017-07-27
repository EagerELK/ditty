# frozen_string_literal: true

require 'ditty/components/app/models/base'

module Ditty
  class AuditLog < Sequel::Model
    include ::Ditty::Base
    many_to_one :user

    def validate
      validates_presence [:action]
    end
  end
end
