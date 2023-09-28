# frozen_string_literal: true

module Ditty
  module Services
    class OpenTelemetry
      def tracer
        # ::OpenTelemetry::Instrumentation::Sinatra::Instrumentation.instance.tracer
        @tracer ||= ::OpenTelemetry.tracer_provider.tracer('Ditty', ::Ditty::VERSION)
      end

      def instrumented?
        (ENV['DITTY_TELEMETRY_DISABLED'] || 0).to_i != 1
      end

      def instrumented(span_name, attribs = {})
        return yield unless instrumented?

        tracer.in_span(span_name, attributes: base_attributes.merge(attribs)) do |span|
          yield(span)
        end
      end

      def application_error(error, opts = {})
        return unless error.is_a? StandardError
        return unless @request_span

        request = opts[:target].request
        @request_span&.record_exception(
          error,
          attributes: base_attributes.merge(
            ::OpenTelemetry::SemanticConventions::Trace::HTTP_URL => request.url,
            ::OpenTelemetry::SemanticConventions::Trace::HTTP_METHOD => request.request_method,
            ::OpenTelemetry::SemanticConventions::Trace::HTTP_STATUS_CODE => opts[:error_code] || 500
          )
        )
        if (opts[:error_code] || 500) >= 500
          @request_span&.status = ::OpenTelemetry::Trace::Status.error("Application Error: #{error.class}")
        end
        @request_span&.finish
      end

      private

        def base_attributes
          {
            'ditty.version' => ::Ditty::VERSION,
          }
        end
    end
  end
end

Wisper.subscribe(::Ditty::Services::OpenTelemetry.new, on: %i[application_error]) unless ENV['RACK_ENV'] == 'test'
