# frozen_string_literal: true

require 'ditty/controllers/component_controller'
require 'ditty/models/user_login_trait'
require 'ditty/policies/user_login_trait_policy'

module Ditty
  class UserLoginTraitsController < ::Ditty::ComponentController
    SEARCHABLE = %i[platform device browser ip_address].freeze
    FILTERS = [
      { name: :user, field: 'user.email' }
    ].freeze

    set base_path: '/login-traits'
    set model_class: UserLoginTrait
    set heading: 'Login'
    # set track_actions: true
  end
end
