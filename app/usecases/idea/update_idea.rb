# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class UpdateIdea
        def initialize(idea_repository)
          @idea_repository = idea_repository
        end

        def call(input)
          idea = @idea_repository.find_by_id(input[:id])
          return Domain::Result.err("Idea not found") unless idea
          return Domain::Result.err("Forbidden") unless idea.account_id == input[:account_id]

          title = input[:title].to_s.strip
          description = input[:description].to_s.strip
          return Domain::Result.err("Title cannot be blank") if title.empty?

          updated = idea.update_title(title).update_description(description)
          idea = @idea_repository.update(updated)

          Domain::Result.ok(idea: idea)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
