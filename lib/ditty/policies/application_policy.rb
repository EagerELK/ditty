# frozen_string_literal: true

module Ditty
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def permitted_attributes
      []
    end

    def method_missing(method_name, *args, &block)
      return super unless method_name.to_s.start_with? 'permitted_attributes_for_'

      permitted_attributes
    end

    def respond_to_missing?(method_name, _include_private = false)
      return super unless method_name.to_s.start_with? 'permitted_attributes_for_'

      true
    end

    def response_attributes
      permitted_attributes
    end

    class Scope
      attr_reader :user, :scope

      def initialize(user, scope)
        @user = user
        @scope = scope
      end
    end
  end
end
