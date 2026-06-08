Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id, type: :Bignum
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
