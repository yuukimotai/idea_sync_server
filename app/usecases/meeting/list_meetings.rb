# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      class ListMeetings
        def initialize(meeting_repository)
          @meeting_repository = meeting_repository
        end

        def call(account:)
          meetings =
            if account.admin?
              @meeting_repository.list_all
            else
              @meeting_repository.list_for_account(account.id)
            end
          Domain::Result.ok(meetings: meetings)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
