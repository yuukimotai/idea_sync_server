Sequel.migration do
  up do
    create_table(:ai_chat_sessions) do
      column :id, :uuid, primary_key: true
      foreign_key :account_id, :accounts, type: :uuid, null: false
      foreign_key :idea_id, :ideas, type: :uuid, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:account_id, :idea_id], unique: true
    end

    create_table(:ai_chat_messages) do
      column :id, :uuid, primary_key: true
      foreign_key :session_id, :ai_chat_sessions, type: :uuid, null: false
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
