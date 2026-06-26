Sequel.migration do
  up do
    alter_table(:messages) do
      add_foreign_key :meeting_id, :meetings, type: :uuid, null: true, on_delete: :cascade
    end
    add_index :messages, :meeting_id
  end

  down do
    drop_index :messages, :meeting_id
    alter_table(:messages) do
      drop_column :meeting_id
    end
  end
end
