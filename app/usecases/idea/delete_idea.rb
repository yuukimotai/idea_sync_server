# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class DeleteIdea
        def initialize(idea_repository)
          @idea_repository = idea_repository
        end

        def call(input)
          idea = @idea_repository.find_by_id(input[:id])
          return Domain::Result.err("Idea not found") unless idea

          @idea_repository.delete(input[:id])
          Domain::Result.ok(success: true)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
