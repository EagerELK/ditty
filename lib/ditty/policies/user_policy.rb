# frozen_string_literal: true

require 'ditty/policies/application_policy'

module Ditty
  class UserPolicy < ApplicationPolicy
    def create?
      user && (user.user_admin? || user.super_admin?)
    end

    def list?
      create?
    end

    def read?
      user && (record.id == user.id || user.user_admin? || user.super_admin?)
    end

    def update?
      read?
    end

    def delete?
      create?
    end

    def permitted_attributes
      attribs = %i[email name surname]
      attribs << :role_id if (user.user_admin? || user.super_admin?)
      attribs
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user && (user.user_admin? || user.super_admin?)
          scope
        elsif user
          scope.where(id: user.id)
        else
          scope.where(id: -1)
        end
      end
    end
  end
end
