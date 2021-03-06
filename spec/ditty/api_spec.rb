# frozen_string_literal: true

require 'spec_helper'
Dir.glob('./lib/ditty/controllers/*.rb').sort.each { |f| require f }
require 'support/api_shared_examples'

describe ::Ditty::RolesController, type: :controller do
  def app
    described_class
  end

  let(:user) { create(:super_admin_user) }

  before do
    env 'rack.session', 'user_id' => user.id
  end

  it_behaves_like 'an API interface', :role, {}
end

describe ::Ditty::UsersController, type: :controller do
  def app
    described_class
  end

  let(:user) { create(:super_admin_user) }

  before { env 'rack.session', 'user_id' => user.id }

  params = {
    identity: {
      username: 'test-user@abc.abc',
      password: 'som3Password!',
      password_confirmation: 'som3Password!'
    }
  }

  it_behaves_like 'an API interface', :user, params
end

describe ::Ditty::UserLoginTraitsController, type: :controller do
  def app
    described_class
  end

  let(:user) { create(:super_admin_user) }

  before { env 'rack.session', 'user_id' => user.id }

  it_behaves_like 'an API interface', :user_login_trait, {}
end
