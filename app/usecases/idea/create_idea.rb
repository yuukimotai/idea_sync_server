# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Idea
      class CreateIdea < HanamiAuthApp::Operation
        input :account_id, :title, :description
        output :idea

        def call(input)
          title = input[:title].to_s.strip
          description = input[:description].to_s.strip

          return Failure(message: "Title cannot be blank") if title.empty?

          idea = container[:idea_repository].create(
            account_id: input[:account_id],
            title: title,
            description: description
          )

          Success(idea: idea)
        rescue => e
          Failure(message: e.message)
        end
      end
    end
  end
end
