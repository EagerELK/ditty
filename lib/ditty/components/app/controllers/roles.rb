# frozen_string_literal: true

require 'ditty/components/app/controllers/component'
require 'ditty/components/app/models/role'
require 'ditty/components/app/policies/role_policy'

module Ditty
  class Roles < Ditty::Component
    set model_class: Role

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Basic Plugin
    end
  end
end
