# frozen_string_literal: true

require 'ditty/policies/application_policy'

module Ditty
  class IdentityPolicy < ApplicationPolicy
    def login?
      true
    end

    def forgot_password?
      true
    end

    def reset_password?
      true
    end

    def permitted_attributes
      %i[username password password_confirmation]
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.super_admin?
          scope
        else
          scope.where(id: -1)
        end
      end
    end
  end
end
