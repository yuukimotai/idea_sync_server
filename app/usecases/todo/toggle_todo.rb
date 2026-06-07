# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Todo
      class ToggleTodo < HanamiAuthApp::Operation
        input :id
        output :todo

        def call(input)
          todo = container[:todo_repository].find_by_id(input[:id])
          return Failure(message: "Todo not found") unless todo

          toggled = todo.toggle
          todo = container[:todo_repository].update(toggled)
          Success(todo: todo)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
