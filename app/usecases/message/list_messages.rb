# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Message
      class ListMessages
        def initialize(message_repository)
          @message_repository = message_repository
        end

        def call(limit: 50)
          messages = @message_repository.list_recent(limit: limit)
          Domain::Result.ok(messages: messages)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
