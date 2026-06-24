Sequel.migration do
  up do
    alter_table(:meetings) do
      set_column_allow_null :idea_id
      add_column :purpose, String, null: false, default: "brainstorm"
      add_column :passcode, String, size: 8
      add_constraint(:meetings_purpose_check, "purpose IN ('ideation', 'refinement', 'brainstorm')")
    end

    # Fill any existing rows (dev: empty, but safety net)
    run <<~SQL
      UPDATE meetings
      SET passcode = upper(substr(md5(random()::text), 1, 6))
      WHERE passcode IS NULL
    SQL

    run "ALTER TABLE meetings ALTER COLUMN passcode SET NOT NULL"
    add_index :meetings, :passcode, unique: true
  end

  down do
    drop_index :meetings, :passcode
    alter_table(:meetings) do
      drop_constraint(:meetings_purpose_check)
      drop_column :purpose
      drop_column :passcode
      set_column_not_null :idea_id
    end
  end
end
