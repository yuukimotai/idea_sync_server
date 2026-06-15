# frozen_string_literal: true

require "sequel"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class MessageRepository < Domain::Message::MessageRepository
      def initialize(db = nil)
        @db = db || Sequel.connect(ENV.fetch("DATABASE_URL"))
      end

      def create(account_id:, body:)
        id = HanamiAuthApp::Uuid7.generate
        @db[:messages].insert(
          id: id,
          account_id: account_id,
          body: body,
          created_at: Time.now,
          updated_at: Time.now
        )
        find_by_id(id)
      end

      def list_recent(limit: 50)
        @db[:messages]
          .order(Sequel.desc(:created_at))
          .limit(limit)
          .reverse_order
          .map { |row| to_entity(row) }
      end

      private

      def find_by_id(id)
        row = @db[:messages].where(id: id).first
        to_entity(row) if row
      end

      def to_entity(row)
        Domain::Message::Message.new(
          id: row[:id],
          account_id: row[:account_id],
          body: row[:body],
          created_at: row[:created_at]
        )
      end
    end
  end
end
