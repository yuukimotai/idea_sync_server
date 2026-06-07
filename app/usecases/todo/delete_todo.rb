# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Todo
      class DeleteTodo < HanamiAuthApp::Operation
        input :id
        output :success

        def call(input)
          todo = container[:todo_repository].find_by_id(input[:id])
          return Failure(message: "Todo not found") unless todo

          container[:todo_repository].delete(input[:id])
          Success(success: true)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
