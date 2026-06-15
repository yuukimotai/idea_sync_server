# frozen_string_literal: true

require "sequel"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class AiChatMessageRepository < Domain::AiChat::AiChatMessageRepository
      def initialize(db = nil)
        @db = db || Sequel.connect(ENV.fetch("DATABASE_URL"))
      end

      def create(session_id:, role:, body:)
        id = HanamiAuthApp::Uuid7.generate
        @db[:ai_chat_messages].insert(
          id: id,
          session_id: session_id,
          role: role,
          body: body,
          created_at: Time.now
        )
        find_by_id(id)
      end

      def list_by_session(session_id:)
        @db[:ai_chat_messages]
          .where(session_id: session_id)
          .order(:created_at)
          .map { |row| to_entity(row) }
      end

      private

      def find_by_id(id)
        row = @db[:ai_chat_messages].where(id: id).first
        to_entity(row) if row
      end

      def to_entity(row)
        Domain::AiChat::AiChatMessage.new(
          id: row[:id],
          session_id: row[:session_id],
          role: row[:role],
          body: row[:body],
          created_at: row[:created_at]
        )
      end
    end
  end
end
