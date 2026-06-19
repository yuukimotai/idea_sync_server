# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      # 呼び出し元がその会議で何をできるか（capabilities）を返す。
      # フロントの表示出し分け用。
      class MeetingPermissions
        def initialize(meeting_repository, participant_repository)
          @meeting_repository = meeting_repository
          @participant_repository = participant_repository
        end

        def call(account:, meeting_id:)
          meeting = @meeting_repository.find_by_id(meeting_id)
          return Domain::Result.err("Meeting not found") unless meeting

          mine = @participant_repository.find_participation(
            meeting_id: meeting_id, account_id: account.id
          )
          policy = Domain::Meeting::MeetingPolicy.new(account: account, participant: mine)
          Domain::Result.ok(capabilities: policy.capabilities)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
