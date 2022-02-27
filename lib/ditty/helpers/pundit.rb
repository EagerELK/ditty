# frozen_string_literal: true

require 'pundit'

module Ditty
  module Helpers
    module Pundit
      include ::Pundit::Authorization

      def authorize(record, query)
        query = :"#{query}?" unless query[-1] == '?'
        super
      end

      def permitted_attributes(record, action = nil)
        policy = policy(record)
        action ||= record.new? ? :create : :update
        method_name = if policy.respond_to?("permitted_attributes_for_#{action}")
          "permitted_attributes_for_#{action}"
        else
          'permitted_attributes'
        end
        policy.public_send(method_name)
      end

      def permitted_parameters(record, action = nil)
        param_key = ::Pundit::PolicyFinder.new(record).param_key
        policy_fields = permitted_attributes(record, action)
        request.params.fetch(param_key, {}).select do |key, _value|
          policy_fields.include? key.to_sym
        end
      end

      def permitted_response_attributes(record, method = :values)
        policy = policy(record)
        response = record.send(method)

        return response unless policy.respond_to? :response_attributes

        policy_fields = policy.response_attributes
        response.select do |key, _value|
          policy_fields.include? key.to_sym
        end
      end

      def pundit_user
        current_user unless current_user&.anonymous?
      end
    end
  end
end
