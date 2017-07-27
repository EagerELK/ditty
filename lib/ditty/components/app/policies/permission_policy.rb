# frozen_string_literal: true

require 'ditty/components/app/policies/application_policy'

module Ditty
  class PermissionPolicy < ApplicationPolicy
    def create?
      user && user.super_admin?
    end

    def list?
      create?
    end

    def read?
      create?
    end

    def update?
      read?
    end

    def delete?
      create?
    end

    def permitted_attributes
      [:verb, :pattern, :role_id, :user_id]
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user && user.super_admin?
          scope
        else
          scope.where(id: -1)
        end
      end
    end
  end
end
