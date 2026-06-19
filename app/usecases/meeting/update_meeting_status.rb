# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      # 会議の状態遷移（draft→active→closed）。進行（facilitator）のみ。
      # 機能ロールが実際の権限を持つことを示す具体例。
      class UpdateMeetingStatus
        def initialize(meeting_repository, participant_repository)
          @meeting_repository = meeting_repository
          @participant_repository = participant_repository
        end

        def call(account:, meeting_id:, status:)
          meeting = @meeting_repository.find_by_id(meeting_id)
          return Domain::Result.err("Meeting not found") unless meeting

          status = status.to_s
          unless Domain::Meeting::Meeting::STATUSES.include?(status)
            return Domain::Result.err("Invalid status")
          end

          mine = @participant_repository.find_participation(
            meeting_id: meeting_id, account_id: account.id
          )
          policy = Domain::Meeting::MeetingPolicy.new(account: account, participant: mine)
          return Domain::Result.err("Forbidden") unless policy.can_progress_meeting?

          updated = @meeting_repository.update_status(meeting_id, status)
          Domain::Result.ok(meeting: updated)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
