# frozen_string_literal: true

require "sequel"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class AiChatSessionRepository < Domain::AiChat::AiChatSessionRepository
      def initialize(db = nil)
        @db = db || Sequel.connect(ENV.fetch("DATABASE_URL"))
      end

      def find_by_account_and_idea(account_id:, idea_id:)
        row = @db[:ai_chat_sessions]
          .where(account_id: account_id, idea_id: idea_id)
          .first
        to_entity(row) if row
      end

      def create(account_id:, idea_id:)
        id = HanamiAuthApp::Uuid7.generate
        @db[:ai_chat_sessions].insert(
          id: id,
          account_id: account_id,
          idea_id: idea_id,
          created_at: Time.now,
          updated_at: Time.now
        )
        find_by_id(id)
      end

      def find_by_id(id)
        row = @db[:ai_chat_sessions].where(id: id).first
        to_entity(row) if row
      end

      private

      def to_entity(row)
        Domain::AiChat::AiChatSession.new(
          id: row[:id],
          account_id: row[:account_id],
          idea_id: row[:idea_id],
          created_at: row[:created_at],
          updated_at: row[:updated_at]
        )
      end
    end
  end
end
