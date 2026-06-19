# frozen_string_literal: true

require "sequel"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class MeetingParticipantRepository < Domain::Meeting::MeetingParticipantRepository
      def initialize(db = nil)
        @db = db || Sequel.connect(ENV.fetch("DATABASE_URL"))
      end

      def add(meeting_id:, account_id:)
        id = HanamiAuthApp::Uuid7.generate
        @db[:meeting_participants].insert(
          id: id,
          meeting_id: meeting_id,
          account_id: account_id,
          created_at: Time.now,
          updated_at: Time.now
        )
        find_by_id(id)
      end

      def find_by_id(id)
        row = @db[:meeting_participants].where(id: id).first
        to_entity(row) if row
      end

      def find_participation(meeting_id:, account_id:)
        row = @db[:meeting_participants]
          .where(meeting_id: meeting_id, account_id: account_id)
          .first
        to_entity(row) if row
      end

      def list_by_meeting(meeting_id)
        rows = @db[:meeting_participants]
          .where(meeting_id: meeting_id)
          .order(:created_at)
          .all
        rows.map { |row| to_entity(row) }
      end

      def assign_role(participant_id:, role:)
        # 既に同じロールがあれば二重登録しない（unique制約もあるが事前にチェック）
        existing = @db[:meeting_role_assignments]
          .where(meeting_participant_id: participant_id, role: role)
          .first
        return if existing

        @db[:meeting_role_assignments].insert(
          id: HanamiAuthApp::Uuid7.generate,
          meeting_participant_id: participant_id,
          role: role,
          created_at: Time.now
        )
      end

      def revoke_role(participant_id:, role:)
        @db[:meeting_role_assignments]
          .where(meeting_participant_id: participant_id, role: role)
          .delete
      end

      private

      def roles_for(participant_id)
        @db[:meeting_role_assignments]
          .where(meeting_participant_id: participant_id)
          .order(:role)
          .select_map(:role)
      end

      def to_entity(row)
        Domain::Meeting::MeetingParticipant.new(
          id: row[:id],
          meeting_id: row[:meeting_id],
          account_id: row[:account_id],
          roles: roles_for(row[:id]),
          created_at: row[:created_at],
          updated_at: row[:updated_at]
        )
      end
    end
  end
end
