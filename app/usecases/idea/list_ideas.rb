# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class ListIdeas
        def initialize(idea_repository)
          @idea_repository = idea_repository
        end

        def call(account_id:)
          ideas = @idea_repository.list_by_account(account_id)
          Domain::Result.ok(ideas: ideas)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
