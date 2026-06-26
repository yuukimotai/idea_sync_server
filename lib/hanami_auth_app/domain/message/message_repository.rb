# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Message
      class MessageRepository
        def create(account_id:, body:, meeting_id: nil)
          raise NotImplementedError
        end

        def list_recent(limit: 50)
          raise NotImplementedError
        end

        def list_by_meeting(meeting_id:, limit: 50)
          raise NotImplementedError
        end
      end
    end
  end
end
