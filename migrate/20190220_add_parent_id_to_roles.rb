# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :roles do
      add_column :parent_id, Integer
    end
  end
end
