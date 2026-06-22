# frozen_string_literal: true

require_relative "../../lib/hanami_auth_app/database"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class IdeaRepository < Domain::Idea::IdeaRepository
      def initialize(db = nil)
        @db = db || HanamiAuthApp::Database.connection
      end

      def create(account_id:, title:, description:)
        id = HanamiAuthApp::Uuid7.generate
        @db[:ideas].insert(
          id: id,
          account_id: account_id,
          title: title,
          description: description,
          created_at: Time.now,
          updated_at: Time.now
        )

        idea_row = @db[:ideas].where(id: id).first
        to_entity(idea_row)
      end

      def find_by_id(id)
        row = @db[:ideas].where(id: id).first
        return nil unless row

        to_entity(row)
      end

      def list_by_account(account_id)
        rows = @db[:ideas].where(account_id: account_id).order(:created_at).all
        rows.map { |row| to_entity(row) }
      end

      def update(idea)
        @db[:ideas].where(id: idea.id).update(
          title: idea.title,
          description: idea.description,
          updated_at: Time.now
        )

        find_by_id(idea.id)
      end

      def delete(id)
        @db[:ideas].where(id: id).delete
      end

      private

      def to_entity(row)
        Domain::Idea::Idea.new(
          id: row[:id],
          account_id: row[:account_id],
          title: row[:title],
          description: row[:description],
          created_at: row[:created_at],
          updated_at: row[:updated_at]
        )
      end
    end
  end
end
