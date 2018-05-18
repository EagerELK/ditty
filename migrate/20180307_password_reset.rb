# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :identities do
      add_column :reset_token, String
      add_column :reset_requested, DateTime
    end
  end
end
