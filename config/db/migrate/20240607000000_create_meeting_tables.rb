Sequel.migration do
  up do
    # 会議。1つのアイデアに紐づき、admin（created_by）が作成する。
    create_table(:meetings) do
      column :id, :uuid, primary_key: true
      foreign_key :idea_id, :ideas, type: :uuid, null: false
      foreign_key :created_by, :accounts, type: :uuid, null: false
      String :title, null: false
      String :status, null: false, default: "draft"
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :idea_id
      index :created_by

      constraint(:meetings_status_check, "status IN ('draft', 'active', 'closed')")
    end

    # 会議の参加者。1人は1会議に1レコード。
    create_table(:meeting_participants) do
      column :id, :uuid, primary_key: true
      foreign_key :meeting_id, :meetings, type: :uuid, null: false, on_delete: :cascade
      foreign_key :account_id, :accounts, type: :uuid, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index [:meeting_id, :account_id], unique: true
    end

    # 参加者の機能ロール（多対多）。1参加者が複数ロールを持てる。
    create_table(:meeting_role_assignments) do
      column :id, :uuid, primary_key: true
      foreign_key :meeting_participant_id, :meeting_participants, type: :uuid, null: false, on_delete: :cascade
      String :role, null: false
      DateTime :created_at, null: false

      index [:meeting_participant_id, :role], unique: true

      constraint(
        :meeting_role_check,
        "role IN ('facilitator', 'timekeeper', 'secretary', 'presenter')"
      )
    end
  end

  down do
    drop_table(:meeting_role_assignments)
    drop_table(:meeting_participants)
    drop_table(:meetings)
  end
end
