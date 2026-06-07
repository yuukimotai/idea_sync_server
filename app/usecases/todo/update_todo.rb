# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Todo
      class UpdateTodo < HanamiAuthApp::Operation
        input :id, :title, :completed
        output :todo

        def call(input)
          todo = container[:todo_repository].find_by_id(input[:id])
          return Failure(message: "Todo not found") unless todo

          title = input[:title].to_s.strip
          return Failure(message: "Title cannot be blank") if title.empty?

          updated = todo.update_title(title)
          updated = HanamiAuthApp::Domain::Todo::Todo.new(
            id: updated.id,
            account_id: updated.account_id,
            title: updated.title,
            completed: input[:completed] || todo.completed,
            created_at: updated.created_at,
            updated_at: updated.updated_at
          )

          todo = container[:todo_repository].update(updated)
          Success(todo: todo)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
