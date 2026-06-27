# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      class AddParticipant
        def initialize(meeting_repository, participant_repository, account_repository)
          @meeting_repository = meeting_repository
          @participant_repository = participant_repository
          @account_repository = account_repository
        end

        def call(account:, meeting_id:, target_account_id:)
          return Domain::Result.err("Forbidden") unless account.admin?

          meeting = @meeting_repository.find_by_room_code(meeting_id) ||
                    @meeting_repository.find_by_id(meeting_id)
          return Domain::Result.err("Meeting not found") unless meeting

          target = @account_repository.find_by_id(target_account_id)
          return Domain::Result.err("Account not found") unless target

          existing = @participant_repository.find_participation(
            meeting_id: meeting.id, account_id: target_account_id
          )
          return Domain::Result.err("Already a participant") if existing

          participant = @participant_repository.add(
            meeting_id: meeting.id, account_id: target_account_id
          )
          Domain::Result.ok(participant: participant)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
