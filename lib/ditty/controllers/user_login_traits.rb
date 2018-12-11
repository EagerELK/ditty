# frozen_string_literal: true

require 'ditty/controllers/component'
require 'ditty/models/user_login_trait'
require 'ditty/policies/user_login_trait_policy'

module Ditty
  class UserLoginTraits < Ditty::Component
    SEARCHABLE = %i[platform device browser ip_address].freeze
    FILTERS = [
      { name: :user, field: 'user.email' }
    ].freeze

    set base_path: 'login-traits'
    set model_class: UserLoginTrait

    # set track_actions: true

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Ditty
    end
  end
end
