# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      class JoinMeeting
        def initialize(meeting_repository, meeting_participant_repository)
          @meeting_repository = meeting_repository
          @meeting_participant_repository = meeting_participant_repository
        end

        def call(account_id:, room_code:, passcode:)
          meeting = @meeting_repository.find_by_room_code_and_passcode(room_code, passcode)
          return Domain::Result.err("Meeting not found") unless meeting
          return Domain::Result.err("Meeting is closed") if meeting.status == "closed"

          existing = @meeting_participant_repository.find_participation(
            meeting_id: meeting.id,
            account_id: account_id
          )
          participant = existing || @meeting_participant_repository.add(
            meeting_id: meeting.id,
            account_id: account_id
          )

          Domain::Result.ok(meeting: meeting, participant: participant)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
