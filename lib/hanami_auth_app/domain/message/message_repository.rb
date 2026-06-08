# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Message
      class MessageRepository
        def create(account_id:, body:)
          raise NotImplementedError
        end

        def list_recent(limit: 50)
          raise NotImplementedError
        end
      end
    end
  end
end
