# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Idea
      class IdeaRepository
        def create(account_id:, title:, description:)
          raise NotImplementedError
        end

        def find_by_id(id)
          raise NotImplementedError
        end

        def list_by_account(account_id)
          raise NotImplementedError
        end

        def update(idea)
          raise NotImplementedError
        end

        def delete(id)
          raise NotImplementedError
        end
      end
    end
  end
end
