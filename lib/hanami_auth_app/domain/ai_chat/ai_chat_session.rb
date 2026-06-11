# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module AiChat
      class AiChatSession
        attr_reader :id, :account_id, :idea_id, :created_at, :updated_at

        def initialize(id:, account_id:, idea_id:, created_at: nil, updated_at: nil)
          @id = id
          @account_id = account_id
          @idea_id = idea_id
          @created_at = created_at
          @updated_at = updated_at
        end

        def ==(other)
          other.is_a?(AiChatSession) && other.id == @id
        end
      end
    end
  end
end
