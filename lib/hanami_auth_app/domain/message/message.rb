# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Message
      class Message
        attr_reader :id, :account_id, :meeting_id, :body, :created_at

        def initialize(id:, account_id:, body:, created_at:, meeting_id: nil)
          @id = id
          @account_id = account_id
          @meeting_id = meeting_id
          @body = body
          @created_at = created_at
        end

        def ==(other)
          other.is_a?(Message) && other.id == @id
        end
      end
    end
  end
end
