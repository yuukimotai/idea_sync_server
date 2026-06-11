# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module AiChat
      class ListMessages
        def initialize(session_repository, message_repository)
          @session_repository = session_repository
          @message_repository = message_repository
        end

        def call(account_id:, session_id:)
          session = @session_repository.find_by_id(session_id)
          return Domain::Result.err("Session not found") unless session
          return Domain::Result.err("Forbidden") unless session.account_id == account_id

          messages = @message_repository.list_by_session(session_id: session_id)
          Domain::Result.ok(messages: messages)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
