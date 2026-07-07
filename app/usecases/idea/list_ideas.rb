# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class ListIdeas
        def initialize(idea_repository)
          @idea_repository = idea_repository
        end

        def call(account_id:, q: nil, sort: nil, order: nil)
          ideas = @idea_repository.list_by_account(
            account_id,
            q: q,
            sort: sort || "created_at",
            order: order || "asc"
          )
          Domain::Result.ok(ideas: ideas)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
