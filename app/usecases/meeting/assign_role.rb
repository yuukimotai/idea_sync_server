# frozen_string_literal: true

module HanamiAuthApp
  module Usecases
    module Meeting
      # 機能ロール（進行/タイムキーパー/書記/発表）の付与。admin のみ。
      # 対象が未参加なら参加者として追加してからロールを付与する。
      class AssignRole
        def initialize(meeting_repository, participant_repository, account_repository)
          @meeting_repository = meeting_repository
          @participant_repository = participant_repository
          @account_repository = account_repository
        end

        def call(account:, meeting_id:, target_account_id:, role:)
          return Domain::Result.err("Forbidden") unless account.admin?

          role = role.to_s
          unless Domain::Meeting::MeetingPolicy::ROLES.include?(role)
            return Domain::Result.err("Invalid role")
          end

          meeting = @meeting_repository.find_by_id(meeting_id)
          return Domain::Result.err("Meeting not found") unless meeting

          target = @account_repository.find_by_id(target_account_id)
          return Domain::Result.err("Account not found") unless target

          participant = @participant_repository.find_participation(
            meeting_id: meeting_id, account_id: target_account_id
          )
          participant ||= @participant_repository.add(
            meeting_id: meeting_id, account_id: target_account_id
          )

          @participant_repository.assign_role(participant_id: participant.id, role: role)

          updated = @participant_repository.find_participation(
            meeting_id: meeting_id, account_id: target_account_id
          )
          Domain::Result.ok(participant: updated)
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
