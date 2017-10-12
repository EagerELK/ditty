# frozen_string_literal: true

require 'spec_helper'
require 'ditty/controllers/component'
require 'ditty/helpers/component'
require 'ditty/models/user'

class DummyComponent < Ditty::Component
  set model_class: Ditty::User

  FILTERS = [{ name: :email }]
  SEARCHABLE = [:email, :name]
end

describe Ditty::Helpers::Component do
  def app
    DummyComponent
  end

  let(:user) { create(:super_admin_user) }
  let(:model) { create(app.model_class.name.to_sym) }
  let(:create_data) do
    group = described_class.model_class.to_s.demodulize.underscore
    identity = build(:identity).to_hash
    identity['password_confirmation'] = identity['password'] = 'som3Password!'
    {
      group => build(described_class.model_class.name.to_sym).to_hash,
      'identity' => identity
    }
  end
  let(:update_data) do
    group = described_class.model_class.to_s.demodulize.underscore
    { group => build(described_class.model_class.name.to_sym).to_hash }
  end
  let(:invalid_create_data) do
    group = described_class.model_class.to_s.demodulize.underscore
    { group => { email: 'invalidemail' } }
  end
  let(:invalid_update_data) do
    group = described_class.model_class.to_s.demodulize.underscore
    { group => { email: 'invalidemail' } }
  end

  before(:each) do
    env 'rack.session', 'user_id' => user.id
    create(:user, email: 'bruce@wayne.com')
  end

  describe 'filters' do
    it 'returns the matching items' do
      header 'Accept', 'application/json'
      get '/', email: 'bruce@wayne.com'

      response = JSON.parse last_response.body
      expect(response['count']).to eq(1)
    end

    it 'returns no items' do
      header 'Accept', 'application/json'
      get '/', email: 'not found'

      response = JSON.parse last_response.body
      expect(response['count']).to eq(0)
    end
  end

  describe 'search' do
    it 'returns the matching items' do
      header 'Accept', 'application/json'
      get '/', q: 'wayne'

      response = JSON.parse last_response.body
      expect(response['count']).to eq(1)
    end

    it 'returns no items' do
      header 'Accept', 'application/json'
      get '/', q: 'not found'

      response = JSON.parse last_response.body
      expect(response['count']).to eq(0)
    end
  end
end
