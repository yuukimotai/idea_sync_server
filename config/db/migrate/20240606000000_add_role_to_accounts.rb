Sequel.migration do
  up do
    alter_table(:accounts) do
      add_column :role, String, null: false, default: "user"
      add_constraint(:accounts_role_check, "role IN ('user', 'admin')")
    end
  end

  down do
    alter_table(:accounts) do
      drop_constraint(:accounts_role_check)
      drop_column :role
    end
  end
end
