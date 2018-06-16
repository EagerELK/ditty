# frozen_string_literal: true

require 'ditty/policies/application_policy'

module Ditty
  class IdentityPolicy < ApplicationPolicy
    def register?
      !['1', 1, 'true', true, 'yes'].include? ENV['DITTY_REGISTERING_DISABLED']
    end

    def permitted_attributes
      %i[username password password_confirmation]
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.super_admin?
          scope.all
        else
          scope.where(id: -1)
        end
      end
    end
  end
end
