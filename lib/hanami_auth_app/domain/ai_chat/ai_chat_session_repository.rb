# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module AiChat
      class AiChatSessionRepository
        def find_by_account_and_idea(account_id:, idea_id:)
          raise NotImplementedError
        end

        def create(account_id:, idea_id:)
          raise NotImplementedError
        end

        def find_by_id(id)
          raise NotImplementedError
        end
      end
    end
  end
end
