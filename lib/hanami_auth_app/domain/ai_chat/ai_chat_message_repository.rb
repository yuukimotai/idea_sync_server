# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module AiChat
      class AiChatMessageRepository
        def create(session_id:, role:, body:)
          raise NotImplementedError
        end

        def list_by_session(session_id:)
          raise NotImplementedError
        end
      end
    end
  end
end
