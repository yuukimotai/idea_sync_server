# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      class ShowMeeting
        def initialize(meeting_repository, participant_repository)
          @meeting_repository = meeting_repository
          @participant_repository = participant_repository
        end

        def call(account:, meeting_id:)
          meeting = @meeting_repository.find_by_id(meeting_id)
          return Domain::Result.err("Meeting not found") unless meeting

          participants = @participant_repository.list_by_meeting(meeting_id)
          mine = participants.find { |p| p.account_id == account.id }

          policy = Domain::Meeting::MeetingPolicy.new(account: account, participant: mine)
          return Domain::Result.err("Forbidden") unless policy.can_view?

          Domain::Result.ok(
            meeting: meeting,
            participants: participants,
            capabilities: policy.capabilities
          )
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
