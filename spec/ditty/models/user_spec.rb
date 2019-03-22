# frozen_string_literal: true

require 'spec_helper'
require 'ditty/models/user'

describe Ditty::User, type: :model do
  let(:super_admin_role) { create(:role, name: 'super_admin') }
  let(:admin_role) { create(:role, name: 'admin', parent_id: super_admin_role.id) }
  let!(:user_role) { create(:role, name: 'user', parent_id: admin_role.id) }
  let(:super_admin) { create(:user) }
  let(:user) { create(:user) }

  before { super_admin.add_role(super_admin_role) }

  describe '#role?(check)' do
    context 'when a user has a role without a parent' do
      it 'returns true only for specific role' do
        expect(user.role?('user')).to be_truthy
      end

      it 'returns false for other roles' do
        %w[admin super_admin].each do |role|
          expect(user.role?(role)).to be_falsy
        end
      end
    end

    context 'when a user has a role with descendants' do
      it 'returns true for all descendants' do
        %w[user admin super_admin].each do |role|
          expect(super_admin.role?(role)).to be_truthy
        end
      end
    end
  end
end
