# frozen_string_literal: true

module HanamiAuthApp
  # 会議系エンティティ → JSON 変換。各アクションに include して使う。
  module MeetingSerializer
    def meeting_to_json(meeting)
      {
        id: meeting.id,
        idea_id: meeting.idea_id,
        created_by: meeting.created_by,
        title: meeting.title,
        status: meeting.status,
        purpose: meeting.purpose,
        passcode: meeting.passcode,
        created_at: meeting.created_at,
        updated_at: meeting.updated_at
      }
    end

    def participant_to_json(participant)
      {
        id: participant.id,
        meeting_id: participant.meeting_id,
        account_id: participant.account_id,
        roles: participant.roles
      }
    end
  end
end
