# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class UpdateIdea < HanamiAuthApp::Operation
        input :id, :title, :description
        output :idea

        def call(input)
          idea = container[:idea_repository].find_by_id(input[:id])
          return Failure(message: "Idea not found") unless idea

          title = input[:title].to_s.strip
          description = input[:description].to_s.strip
          return Failure(message: "Title cannot be blank") if title.empty?

          updated = idea.update_title(title).update_description(description)
          idea = container[:idea_repository].update(updated)

          Success(idea: idea)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
