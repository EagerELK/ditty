# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :audit_logs do
      add_column :ip_address, String
      add_column :platform, String
      add_column :device, String
      add_column :browser, String
    end
  end
end
