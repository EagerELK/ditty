# frozen_string_literal: true

require 'ditty/emails/base'
require 'ditty/services/email'

module Ditty
  module Emails
    class ForgotPassword < Base
      def initialize(locals = {}, options = nil)
        super(:forgot_password, locals, options)
        @options[:layout] ||= :action
      end
    end
  end
end
