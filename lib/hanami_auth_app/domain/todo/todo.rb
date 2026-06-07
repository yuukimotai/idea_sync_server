# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Todo
      class Todo
        attr_reader :id, :account_id, :title, :completed, :created_at, :updated_at

        def initialize(id:, account_id:, title:, completed: false, created_at: nil, updated_at: nil)
          @id = id
          @account_id = account_id
          @title = title
          @completed = completed
          @created_at = created_at
          @updated_at = updated_at
        end

        def toggle
          Todo.new(
            id: @id,
            account_id: @account_id,
            title: @title,
            completed: !@completed,
            created_at: @created_at,
            updated_at: Time.now
          )
        end

        def update_title(new_title)
          Todo.new(
            id: @id,
            account_id: @account_id,
            title: new_title,
            completed: @completed,
            created_at: @created_at,
            updated_at: Time.now
          )
        end

        def ==(other)
          other.is_a?(Todo) && other.id == @id
        end
      end
    end
  end
end
