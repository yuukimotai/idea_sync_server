# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module AiChat
      class GetOrCreateSession
        def initialize(session_repository, idea_repository)
          @session_repository = session_repository
          @idea_repository = idea_repository
        end

        def call(account_id:, idea_id:)
          idea = @idea_repository.find_by_id(idea_id)
          return Domain::Result.err("Idea not found") unless idea
          return Domain::Result.err("Forbidden") unless idea.account_id == account_id

          session = @session_repository.find_by_account_and_idea(
            account_id: account_id,
            idea_id: idea_id
          )
          session ||= @session_repository.create(account_id: account_id, idea_id: idea_id)

          Domain::Result.ok(session: session, idea: idea)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
