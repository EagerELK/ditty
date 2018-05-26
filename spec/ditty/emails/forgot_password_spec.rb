# frozen_string_literal: true

require 'spec_helper'
require 'ditty/emails/forgot_password'
require 'mail'

describe Ditty::Emails::ForgotPassword do
  let(:mail) do
    mail = Mail.new
    allow(mail).to receive(:deliver!)
    mail
  end

  context '.new' do
    it 'defaults to base options' do
      expect(subject.options).to include subject: 'Request to reset password', from: 'no-reply@ditty.io', view: :forgot_password
    end
  end
end
