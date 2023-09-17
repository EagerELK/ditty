# frozen_string_literal: true

require 'ditty/services/open_telemetry'

module Ditty
  module Middleware
    class Telemetry
      attr_reader :env, :telemetry

      def initialize(app, telemetry = nil)
        @app = app
        @telemetry = telemetry || Services::OpenTelemetry.new
      end

      def call(env)
        @env = env
        request = Rack::Request.new(env)
        attribs = {
          ::OpenTelemetry::SemanticConventions::Trace::HTTP_URL => request.url,
          ::OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request.request_method,
        }

        telemetry.instrumented("#{request.request_method} #{request.path}", attribs) do |span|
          # Not sure if we should try and catch exceptions?
          result = @app.call(env)
          span.add_attributes(
            ::OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE => result[0]
          )
          result
        end
      end

      class << self
        def method_missing(method, *args, &block)
          instance.send(method, *args, &block)
        end

        def respond_to_missing?(method, _include_private)
          return true if instance.respond_to?(method)

          super
        end
      end
    end
  end
end
