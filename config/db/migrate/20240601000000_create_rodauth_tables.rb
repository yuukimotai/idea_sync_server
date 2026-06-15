Sequel.migration do
  up do
    create_table(:accounts) do
      column :id, :uuid, primary_key: true
      String :email, null: false, unique: true
      String :password_digest, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end

  down do
    drop_table(:accounts)
  end
end
