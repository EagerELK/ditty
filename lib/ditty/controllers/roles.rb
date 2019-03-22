# frozen_string_literal: true

require 'ditty/controllers/component'
require 'ditty/models/role'
require 'ditty/policies/role_policy'

module Ditty
  class Roles < Ditty::Component
    SEARCHABLE = %i[name].freeze

    set model_class: Role

    helpers do
      def parent_options(entity)
        policy_scope(Ditty::Role)
          .exclude(id: [entity.id] + entity.descendants.map(&:id))
          .order(:name)
      end
    end
  end
end
