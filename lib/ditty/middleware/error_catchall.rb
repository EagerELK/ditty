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
          ::Ditty::Services::Logger.instance.error "Ditty Catchall: #{e.class}"
          ::Ditty::Services::Logger.instance.error e
          [500, {}, ['Unknown Error']]
        end
      end
    end
  end
end
