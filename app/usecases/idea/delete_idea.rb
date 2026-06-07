# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class DeleteIdea < HanamiAuthApp::Operation
        input :id
        output :success

        def call(input)
          idea = container[:idea_repository].find_by_id(input[:id])
          return Failure(message: "Idea not found") unless idea

          container[:idea_repository].delete(input[:id])
          Success(success: true)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
