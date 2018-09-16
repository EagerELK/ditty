# frozen_string_literal: true

require 'ditty/policies/user_policy'

module Ditty
  class LdapPolicy < UserPolicy
    def register?
      true
    end

    class Scope < UserPolicy::Scope
    end
  end
end
