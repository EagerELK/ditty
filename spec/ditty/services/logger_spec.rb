# frozen_string_literal: true

require 'logger'
require 'spec_helper'
require 'ditty/services/logger'

class TestLogger
  WARN = 2
  attr_accessor :level
  def initialize(options = {})
    @options = options
  end
end

describe Ditty::Services::Logger, type: :service do
  let(:subject) { described_class.clone }
  let(:config_file) { File.read('./spec/fixtures/logger.yml') }

  context 'initialize' do
    it '.instance always refers to the same instance' do
      expect(subject.instance).to eq subject.instance
    end

    it "creates default logger if config file does't exist" do
      expect(subject.instance.loggers[0]).to be_instance_of Logger
    end

    it 'reads config from file and creates an array of loggers' do
      Ditty::Services::Settings.values = nil
      allow(File).to receive(:'file?').and_return(false)
      allow(File).to receive(:'file?').with('./config/logger.yml').and_return(true)
      allow(File).to receive(:read).and_return(config_file)

      expect(subject.instance.loggers.size).to eq 4
      expect(subject.instance.loggers[0]).to be_instance_of Logger
      expect(subject.instance.loggers[1]).to be_instance_of TestLogger
    end
  end

  context 'send messages' do
    it 'receives message and passes it to the loggers' do
      Ditty::Services::Settings.values = nil
      allow(File).to receive(:'file?').and_return(false)
      allow(File).to receive(:'file?').with('./config/logger.yml').and_return(true)
      allow(File).to receive(:read).and_return(config_file)
      allow(Logger).to receive(:warn).with('Some message')
      allow(TestLogger).to receive(:warn).with('Some message')

      expect(subject.instance.loggers[0]).to receive(:warn).with('Some message')
      expect(subject.instance.loggers[1]).to receive(:warn).with('Some message')
      expect($stdout).to receive(:write).with(/Some message$/)
      expect($stderr).to receive(:write).with(/Some message$/)

      subject.instance.warn 'Some message'
    end
  end
end
