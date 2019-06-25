# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :user_login_traits do
      primary_key :id
      foreign_key :user_id, :users
      String :ip_address, null: true
      String :platform, null: true
      String :device, null: true
      String :browser, null: true
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
