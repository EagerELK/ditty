# frozen_string_literal: true

require 'ditty/controllers/component_controller'
require 'ditty/models/user_login_trait'
require 'ditty/policies/user_login_trait_policy'

module Ditty
  class UserLoginTraitsController < ::Ditty::ComponentController
    SEARCHABLE = %i[platform device browser ip_address].freeze
    FILTERS = [
      { name: :user, field: 'user.email' },
      { name: :platform },
      { name: :device },
      { name: :browser }
    ].freeze

    set base_path: '/login-traits'
    set model_class: UserLoginTrait
    set heading: 'Login'
    # set track_actions: true

    helpers do
      def user_options
        policy_scope(::Ditty::User).as_hash(:email, :email)
      end

      def platform_options
        policy_scope(::Ditty::UserLoginTrait).select(:platform).distinct.as_hash(:platform, :platform)
      end

      def device_options
        policy_scope(::Ditty::UserLoginTrait).select(:device).distinct.as_hash(:device, :device)
      end

      def browser_options
        policy_scope(::Ditty::UserLoginTrait).select(:browser).distinct.as_hash(:browser, :browser)
      end
    end
  end
end
