# frozen_string_literal: true

require 'ditty/controllers/component'
require 'ditty/models/role'
require 'ditty/policies/role_policy'

module Ditty
  class Roles < Ditty::Component
    set model_class: Role

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Ditty
    end
  end
end
