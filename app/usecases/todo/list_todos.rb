# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Todo
      class ListTodos < HanamiAuthApp::Operation
        input :account_id
        output :todos

        def call(input)
          todos = container[:todo_repository].list_by_account(input[:account_id])
          Success(todos: todos)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
