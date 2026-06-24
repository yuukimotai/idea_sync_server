# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      class CreateMeeting
        def initialize(meeting_repository, idea_repository)
          @meeting_repository = meeting_repository
          @idea_repository = idea_repository
        end

        def call(account:, title:, purpose:, idea_id: nil)
          title = title.to_s.strip
          return Domain::Result.err("Title cannot be blank") if title.empty?

          unless Domain::Meeting::Meeting::PURPOSES.include?(purpose.to_s)
            return Domain::Result.err("Invalid purpose")
          end

          if idea_id
            idea = @idea_repository.find_by_id(idea_id)
            return Domain::Result.err("Idea not found") unless idea
          end

          meeting = @meeting_repository.create(
            idea_id: idea_id,
            created_by: account.id,
            title: title,
            purpose: purpose
          )
          Domain::Result.ok(meeting: meeting)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
