# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module AiChat
      class AiChatMessage
        attr_reader :id, :session_id, :role, :body, :created_at

        def initialize(id:, session_id:, role:, body:, created_at: nil)
          @id = id
          @session_id = session_id
          @role = role
          @body = body
          @created_at = created_at
        end

        def ==(other)
          other.is_a?(AiChatMessage) && other.id == @id
        end
      end
    end
  end
end
