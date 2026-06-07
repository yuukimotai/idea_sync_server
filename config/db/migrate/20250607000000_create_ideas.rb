Sequel.migration do
  up do
    create_table(:ideas) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, type: :Bignum, null: false
      String :title, null: false
      String :description, null: false, default: ""
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP

      index :account_id
      index [:account_id, :created_at]
    end
  end

  down do
    drop_table(:ideas)
  end
end
