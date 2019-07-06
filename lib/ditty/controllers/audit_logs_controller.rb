# frozen_string_literal: true

require 'ditty/controllers/component_controller'
require 'ditty/models/audit_log'
require 'ditty/policies/audit_log_policy'

module Ditty
  class AuditLogsController < ::Ditty::ComponentController
    set model_class: AuditLog

    SEARCHABLE = %i[details platform device browser ip_address].freeze
    FILTERS = [
      { name: :user, field: 'user.email' },
      { name: :action }
    ].freeze

    helpers do
      def user_options
        policy_scope(::Ditty::User).as_hash(:email, :email)
      end

      def action_options
        policy_scope(::Ditty::AuditLog).as_hash(:action, :action)
      end
    end

    def list
      super.order(:created_at).reverse
    end

    get '/new' do
      halt 404
    end

    post '/' do
      halt 404
    end

    get '/:id' do
      halt 404
    end

    get '/:id/edit' do
      halt 404
    end

    put '/:id' do
      halt 404
    end

    delete '/:id' do
      halt 404
    end
  end
end
