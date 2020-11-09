# frozen_string_literal: true

require 'ditty/policies/application_policy'

module Ditty
  class UserPolicy < ApplicationPolicy
    def register?
      # TODO: Check email domain against settings
      !['1', 1, 'true', true, 'yes'].include? ENV['DITTY_REGISTERING_DISABLED']
    end

    def create?
      user&.super_admin?
    end

    def list?
      create?
    end

    def read?
      user && (record.id == user.id || user.super_admin?)
    end

    def update?
      read?
    end

    def delete?
      create? && record&.super_admin? == false
    end

    def permitted_attributes
      attribs = %i[email name surname]
      attribs << :role_id if user.super_admin?
      attribs
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user&.super_admin?
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
