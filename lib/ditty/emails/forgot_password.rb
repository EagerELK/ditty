# frozen_string_literal: true

require 'ditty/emails/base'
require 'ditty/services/email'

module Ditty
  module Emails
    class ForgotPassword < Base
      def initialize(options = {})
        options = { view: :forgot_password, layout: :action }.merge(options)
        super(options)
      end
    end
  end
end
