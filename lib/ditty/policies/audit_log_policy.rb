# frozen_string_literal: true

require 'ditty/policies/application_policy'

module Ditty
  class AuditLogPolicy < ApplicationPolicy
    def create?
      false
    end

    def list?
      user&.super_admin?
    end

    def read?
      user&.super_admin?
    end

    def update?
      false
    end

    def delete?
      false
    end

    def permitted_attributes
      %i[action details]
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user&.super_admin?
          scope
        else
          scope.where(id: -1)
        end
      end
    end
  end
end
