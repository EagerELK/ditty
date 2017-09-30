# frozen_string_literal: true

require 'ditty/controllers/component'
require 'ditty/models/audit_log'
require 'ditty/policies/audit_log_policy'

module Ditty
  class AuditLogs < Ditty::Component
    set model_class: AuditLog

    def find_template(views, name, engine, &block)
      super(views, name, engine, &block) # Root
      super(::Ditty::App.view_folder, name, engine, &block) # Ditty
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
