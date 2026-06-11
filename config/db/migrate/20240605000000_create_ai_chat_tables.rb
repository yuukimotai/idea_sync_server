Sequel.migration do
  up do
    create_table(:ai_chat_sessions) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, type: :Bignum, null: false
      foreign_key :idea_id, :ideas, type: :Bignum, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:account_id, :idea_id], unique: true
    end

    create_table(:ai_chat_messages) do
      primary_key :id, type: :Bignum
      foreign_key :session_id, :ai_chat_sessions, type: :Bignum, null: false
      String :role, null: false
      String :body, text: true, null: false
      DateTime :created_at, null: false

      index :session_id
      index :created_at
    end
  end

  down do
    drop_table(:ai_chat_messages)
    drop_table(:ai_chat_sessions)
  end
end
