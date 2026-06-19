# frozen_string_literal: true

module HanamiAuthApp
  module Domain
    module Meeting
      # 会議の参加者。roles はその会議で持つ機能ロールの配列。
      class MeetingParticipant
        attr_reader :id, :meeting_id, :account_id, :roles, :created_at, :updated_at

        def initialize(id:, meeting_id:, account_id:, roles: [], created_at: nil, updated_at: nil)
          @id = id
          @meeting_id = meeting_id
          @account_id = account_id
          @roles = roles
          @created_at = created_at
          @updated_at = updated_at
        end

        def role?(role)
          @roles.include?(role.to_s)
        end

        def ==(other)
          other.is_a?(MeetingParticipant) && other.id == @id
        end
      end
    end
  end
end
