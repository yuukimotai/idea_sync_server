Sequel.migration do
  up do
    create_table(:messages) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, type: :Bignum, null: false
      String :body, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end

    add_index :messages, :account_id
    add_index :messages, :created_at
  end

  down do
    drop_table(:messages)
  end
end
