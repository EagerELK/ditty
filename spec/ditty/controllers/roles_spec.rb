# frozen_string_literal: true

require 'spec_helper'
require 'ditty/controllers/roles_controller'
require 'support/crud_shared_examples'

describe Ditty::RolesController do
  def app
    described_class
  end

  context 'as super_admin_user' do
    let(:user) { create(:super_admin_user) }
    let(:model) { create(app.model_class.name.to_sym) }
    let(:create_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => build(described_class.model_class.name.to_sym).to_hash }
    end
    let(:update_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => build(described_class.model_class.name.to_sym).to_hash }
    end
    let(:invalid_create_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => { name: '' } }
    end
    let(:invalid_update_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => { name: '' } }
    end

    before do
      # Log in
      env 'rack.session', 'user_id' => user.id
    end

    it_behaves_like 'a CRUD Controller', '/roles'
  end

  context 'as user' do
    let(:user) { create(:user) }
    let(:model) { create(app.model_class.name.to_sym) }
    let(:create_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => build(described_class.model_class.name.to_sym).to_hash }
    end
    let(:update_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => build(described_class.model_class.name.to_sym).to_hash }
    end
    let(:invalid_create_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => { name: '' } }
    end
    let(:invalid_update_data) do
      group = described_class.model_class.to_s.demodulize.underscore
      { group => { name: '' } }
    end

    before do
      # Log in
      env 'rack.session', 'user_id' => user.id
    end

    it_behaves_like 'a CRUD Controller', '/roles'
  end
end
