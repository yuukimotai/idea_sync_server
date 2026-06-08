# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class CreateIdea
        def initialize(idea_repository)
          @idea_repository = idea_repository
        end

        def call(input)
          title = input[:title].to_s.strip
          description = input[:description].to_s.strip

          return Domain::Result.err("Title cannot be blank") if title.empty?

          idea = @idea_repository.create(
            account_id: input[:account_id],
            title: title,
            description: description
          )

          Domain::Result.ok(idea: idea)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
