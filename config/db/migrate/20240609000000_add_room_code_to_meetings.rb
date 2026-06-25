Sequel.migration do
  up do
    alter_table(:meetings) do
      add_column :room_code, String, size: 12
    end
    run <<~SQL
      UPDATE meetings
      SET room_code = upper(left(md5(random()::text || id::text), 12))
      WHERE room_code IS NULL
    SQL
    alter_table(:meetings) do
      set_column_not_null :room_code
    end
    add_index :meetings, :room_code, unique: true
  end

  down do
    drop_index :meetings, :room_code
    alter_table(:meetings) do
      drop_column :room_code
    end
  end
end
