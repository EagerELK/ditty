# frozen_string_literal: true

require 'ditty/policies/application_policy'

module Ditty
  class UserLoginTraitPolicy < ApplicationPolicy
    def create?
      user&.super_admin?
    end

    def list?
      !!user
    end

    def read?
      user && (record.user_id == user.id || user.super_admin?)
    end

    def update?
      user&.super_admin?
    end

    def delete?
      user&.super_admin?
    end

    def permitted_attributes
      attribs = %i[ip_address os browser]
      attribs << :user_id if user.super_admin?
      attribs
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user&.super_admin?
          scope
        elsif user
          scope.where(user_id: user.id)
        else
          scope.where(id: -1)
        end
      end
    end
  end
end
