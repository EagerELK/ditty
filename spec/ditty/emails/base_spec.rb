# frozen_string_literal: true

require 'spec_helper'
require 'ditty/emails/base'
require 'mail'

describe ::Ditty::Emails::Base do
  let(:mail) do
    mail = Mail.new
    allow(mail).to receive(:deliver!)
    mail
  end

  describe '.new' do
    it 'defaults to base options' do
      expect(subject.options).to include subject: '(No Subject)', from: 'no-reply@ditty.io', view: :base
    end

    it 'allows the use of layouts' do
      skip 'Test is not accurate. The class no longer uses body.'
      base = described_class.new(layout: 'action', mail: mail)
      expect(mail).to receive(:body).with(/^<!DOCTYPE html>/m)
      base.deliver!('test@email.com')
    end
  end

  describe '.deliver!' do
    it 'delivers the email to the specified email address' do
      expect(mail).to receive(:to).with('test@email.com')
      expect(mail).to receive(:deliver!)
      described_class.deliver!('test@email.com', mail: mail)
    end

    it 'passes down local variables' do
      skip 'Test is not accurate. The class no longer uses body.'
      expect(mail).to receive(:body).with("test content\n")
      described_class.deliver!('test@email.com', locals: { content: 'test content' }, mail: mail)
    end

    it 'sets the email\'s subject and from address' do
      expect(mail).to receive(:subject).with('test subject')
      expect(mail).to receive(:from).with('from@test.com')
      described_class.deliver!('test@email.com', subject: 'test subject', from: 'from@test.com', mail: mail)
    end
  end

  describe '#deliver!' do
    it 'delivers the email to the specified email address' do
      expect(mail).to receive(:to).with('test2@email.com')
      base = described_class.new(mail: mail)
      base.deliver!('test2@email.com')
    end

    it 'passes the local variables to the template' do
      skip 'Test is not accurate. The class no longer uses body.'
      expect(mail).to receive(:body).with("test content\n")
      base = described_class.new(mail: mail)
      base.deliver!('test@email.com', content: 'test content')
    end

    it 'sets the email\'s subject and from address' do
      expect(mail).to receive(:subject).with('test subject')
      expect(mail).to receive(:from).with('from@test.com')
      base = described_class.new(subject: 'test subject', from: 'from@test.com', mail: mail)
      base.deliver!('test@email.com')
    end
  end

  context 'method_missing' do
    it 'passes unknown message to the underlying mail object' do
      expect(mail).to receive(:cc).with('cc@test.com')
      base = described_class.new(mail: mail)
      base.cc 'cc@test.com'
    end
  end
end
