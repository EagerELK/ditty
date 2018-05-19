# frozen_string_literal: true

require 'spec_helper'
require 'ditty/services/settings'

describe Ditty::Services::Settings do
  def setup_files
    settings = File.read('./spec/fixtures/settings.yml')
    section = File.read('./spec/fixtures/section.yml')

    allow(File).to receive(:file?).with('./config/settings.yml').and_return(true)
    allow(File).to receive(:file?).with('./config/section.yml').and_return(true)
    allow(File).to receive(:file?).with('./config/no_file_section.yml').and_return(false)

    allow(File).to receive(:read).with('./config/settings.yml').and_return(settings)
    allow(File).to receive(:read).with('./config/section.yml').and_return(section)
  end

  context '#[]' do
    before(:each) do
      setup_files
    end

    it 'returns the specified values from the global settings' do
      expect(described_class[:option_a]).to eq 1
    end

    it 'allows access to sectional settings' do
      expect(described_class[:no_file_section]).to include(section_1: 2, section_2: 'set')
    end
  end

  context '#values' do
    context 'uses the global file' do
      before(:each) do
        setup_files
      end

      it 'to return global settings' do
        expect(described_class.values).to include(option_a: 1, option_b: 'value')
      end

      it 'to return sectional settings' do
        expect(described_class.values(:no_file_section)).to include(section_1: 2, section_2: 'set')
      end
    end

    context 'uses the sectional file' do
      before(:each) do
        setup_files
      end

      it 'prefers the sectional settings file' do
        expect(described_class.values(:section)).to include(section_1: 3, section_2: 'section')
      end
    end
  end
end
