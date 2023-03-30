# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :identities do
      add_column :password_expiry_date, DateTime, null: true
    end

    create_table :password_histories do
      String :id, type: :uniqueidentifier, primary_key: true
      foreign_key :identity_id, :identities
      String :crypted_password
      DateTime :created_at
    end
  end
end

