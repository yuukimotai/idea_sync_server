# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class ListIdeas < HanamiAuthApp::Operation
        input :account_id
        output :ideas

        def call(input)
          ideas = container[:idea_repository].list_by_account(input[:account_id])
          Success(ideas: ideas)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
