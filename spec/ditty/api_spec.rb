# frozen_string_literal: true

require 'spec_helper'
Dir.glob('./lib/ditty/controllers/*.rb').each { |f| require f }
require 'support/api_shared_examples'

describe Ditty::Roles, type: :controller do
  def app
    described_class
  end

  let(:user) { create(:super_admin_user) }

  before(:each) do
    env 'rack.session', 'user_id' => user.id
  end

  it_behaves_like 'an API interface', subject, {}
end

describe Ditty::Users, type: :controller do
  def app
    described_class
  end

  let(:user) { create(:super_admin_user) }

  before { env 'rack.session', 'user_id' => user.id }

  params = {
    identity: {
      username: 'test-user@abc.abc',
      password: '123456789',
      password_confirmation: '123456789'
    }
  }

  it_behaves_like 'an API interface', :user, params
end
