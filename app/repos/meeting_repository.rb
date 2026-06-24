# frozen_string_literal: true

require "sequel"
require_relative "../../lib/hanami_auth_app/database"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class MeetingRepository < Domain::Meeting::MeetingRepository
      def initialize(db = nil)
        @db = db || HanamiAuthApp::Database.connection
      end

      def create(created_by:, title:, purpose:, idea_id: nil)
        id = HanamiAuthApp::Uuid7.generate
        @db[:meetings].insert(
          id: id,
          idea_id: idea_id,
          created_by: created_by,
          title: title,
          purpose: purpose,
          passcode: generate_passcode,
          status: "draft",
          created_at: Time.now,
          updated_at: Time.now
        )
        find_by_id(id)
      end

      def find_by_id_and_passcode(id, passcode)
        row = @db[:meetings].where(id: id, passcode: passcode).first
        to_entity(row) if row
      end

      def find_by_id(id)
        row = @db[:meetings].where(id: id).first
        to_entity(row) if row
      end

      def list_all
        @db[:meetings].order(Sequel.desc(:created_at)).all.map { |row| to_entity(row) }
      end

      # account が参加している会議のみ
      def list_for_account(account_id)
        participant_meeting_ids = @db[:meeting_participants]
          .where(account_id: account_id)
          .select(:meeting_id)
        @db[:meetings]
          .where(id: participant_meeting_ids)
          .order(Sequel.desc(:created_at))
          .all
          .map { |row| to_entity(row) }
      end

      def update_status(id, status)
        @db[:meetings].where(id: id).update(status: status, updated_at: Time.now)
        find_by_id(id)
      end

      private

      PASSCODE_CHARS = ("A".."Z").to_a + ("0".."9").to_a

      def generate_passcode
        loop do
          code = Array.new(6) { PASSCODE_CHARS.sample }.join
          return code unless @db[:meetings].where(passcode: code).first
        end
      end

      def to_entity(row)
        Domain::Meeting::Meeting.new(
          id: row[:id],
          idea_id: row[:idea_id],
          created_by: row[:created_by],
          title: row[:title],
          status: row[:status],
          purpose: row[:purpose],
          passcode: row[:passcode],
          created_at: row[:created_at],
          updated_at: row[:updated_at]
        )
      end
    end
  end
end
