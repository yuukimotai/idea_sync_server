# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Meeting
      # 参加者とその機能ロール（多対多）をまとめて扱う。
      class MeetingParticipantRepository
        def add(meeting_id:, account_id:)
          raise NotImplementedError
        end

        def find_participation(meeting_id:, account_id:)
          raise NotImplementedError
        end

        def list_by_meeting(meeting_id)
          raise NotImplementedError
        end

        def assign_role(participant_id:, role:)
          raise NotImplementedError
        end

        def revoke_role(participant_id:, role:)
          raise NotImplementedError
        end
      end
    end
  end
end
