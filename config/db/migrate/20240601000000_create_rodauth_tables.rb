Sequel.migration do
  up do
    create_table(:accounts) do
      primary_key :id, type: :Bignum
      String :email, null: false
      index :email, unique: true
      Integer :status, null: false, default: 1
    end

    create_table(:account_password_hashes) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :password_hash, null: false
    end
  end

  down do
    drop_table(:account_password_hashes)
    drop_table(:accounts)
  end
end
