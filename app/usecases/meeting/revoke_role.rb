# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      # 機能ロールのはく奪。admin のみ。参加者レコード自体は残す。
      class RevokeRole
        def initialize(meeting_repository, participant_repository)
          @meeting_repository = meeting_repository
          @participant_repository = participant_repository
        end

        def call(account:, meeting_id:, target_account_id:, role:)
          return Domain::Result.err("Forbidden") unless account.admin?

          meeting = @meeting_repository.find_by_room_code(meeting_id) ||
                    @meeting_repository.find_by_id(meeting_id)
          return Domain::Result.err("Meeting not found") unless meeting

          participant = @participant_repository.find_participation(
            meeting_id: meeting.id, account_id: target_account_id
          )
          return Domain::Result.err("Participant not found") unless participant

          @participant_repository.revoke_role(participant_id: participant.id, role: role.to_s)

          updated = @participant_repository.find_participation(
            meeting_id: meeting.id, account_id: target_account_id
          )
          Domain::Result.ok(participant: updated)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
