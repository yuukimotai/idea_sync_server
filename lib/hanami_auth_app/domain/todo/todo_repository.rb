# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Todo
      class TodoRepository
        def create(account_id:, title:)
          raise NotImplementedError
        end

        def find_by_id(id)
          raise NotImplementedError
        end

        def list_by_account(account_id)
          raise NotImplementedError
        end

        def update(todo)
          raise NotImplementedError
        end

        def delete(id)
          raise NotImplementedError
        end
      end
    end
  end
end
