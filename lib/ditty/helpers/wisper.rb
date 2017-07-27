# frozen_string_literal: true

require 'wisper'

module Ditty
  module Helpers
    module Wisper
      def log_action(action, args = {})
        args[:user] ||= current_user
        broadcast(action, args)
      end
    end
  end
end
