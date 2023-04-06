# frozen_string_literal: true

require 'ditty/emails/base'
require 'ditty/services/email'

module Ditty
  module Emails
    class Otp < Base
      def initialize(options = {})
        options = { view: :mfa, layout: :action, subject: 'One Time Password' }.merge(options)
        super(options)
      end
    end
  end
end


