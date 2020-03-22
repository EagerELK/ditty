# frozen_string_literal: true

module Ditty
  module Middleware
    # Allow requests to be responded to in JSON if the URL has .json at the end.
    # The regex and the content_type can be customized to allow for other formats.
    # Some inspiration from https://gist.github.com/tstachl/6264249
    class AcceptExtension
      attr_reader :env, :regex, :content_type

      def initialize(app, regex = %r{\A(.*)\.json(/?)\Z}, content_type = 'application/json')
        # @mutex = Mutex.new
        @app = app
        @regex = regex
        @content_type = content_type
      end

      def call(env)
        @env = env

        request = Rack::Request.new(env)
        if request.path&.match?(regex)
          request.path_info = request.path_info.gsub(regex, '\1\2')
          env = request.env
          env['ACCEPT'] = content_type
          env['CONTENT_TYPE'] = content_type
        end

        @app.call env
      end
    end
  end
end
