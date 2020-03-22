# frozen_string_literal: true

require 'ditty/services/logger'

module Ditty
  module Middleware
    class ErrorCatchall
      attr_reader :env

      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env
        begin
          @app.call env
        rescue StandardError => e
          ::Ditty::Services::Logger.error "Ditty Catchall: #{e.class}"
          ::Ditty::Services::Logger.error e
          [500, {}, ['Unknown Error']]
        end
      end
    end
  end
end
