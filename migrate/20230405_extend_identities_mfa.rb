# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :identities do
      add_column :pin, Integer, null: true
      add_column :pin_expiry_date, DateTime, null: true
      add_column :pin_verified, FalseClass, default: false, null: false
    end
  end
end
