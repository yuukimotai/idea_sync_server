# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Todo
      class CreateTodo < HanamiAuthApp::Operation
        input :account_id, :title
        output :todo

        def call(input)
          title = input[:title].to_s.strip

          if title.empty?
            return Failure(message: "Title cannot be blank")
          end

          todo = container[:todo_repository].create(account_id: input[:account_id], title: title)
          Success(todo: todo)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
