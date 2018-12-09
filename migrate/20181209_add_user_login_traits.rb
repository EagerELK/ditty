# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :user_login_traits do
      primary_key :id
      foreign_key :user_id, :users
      String :ip_address, nullable: true
      String :platform, nullable: true
      String :device, nullable: true
      String :browser, nullable: true
      DateTime :created_at
      DateTime :updated_at
    end
  end
end
