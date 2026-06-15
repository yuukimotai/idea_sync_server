# frozen_string_literal: true

require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class TodoRepository < Domain::Todo::TodoRepository
      def initialize(db = nil)
        @db = db || HanamiAuthApp::RODAUTH_DB
      end

      def create(account_id:, title:)
        id = HanamiAuthApp::Uuid7.generate
        @db[:todos].insert(
          id: id,
          account_id: account_id,
          title: title,
          completed: false,
          created_at: Time.now,
          updated_at: Time.now
        )

        todo_row = @db[:todos].where(id: id).first
        to_entity(todo_row)
      end

      def find_by_id(id)
        row = @db[:todos].where(id: id).first
        return nil unless row

        to_entity(row)
      end

      def list_by_account(account_id)
        rows = @db[:todos].where(account_id: account_id).order(:created_at).all
        rows.map { |row| to_entity(row) }
      end

      def update(todo)
        @db[:todos].where(id: todo.id).update(
          title: todo.title,
          completed: todo.completed,
          updated_at: Time.now
        )

        find_by_id(todo.id)
      end

      def delete(id)
        @db[:todos].where(id: id).delete
      end

      private

      def to_entity(row)
        Domain::Todo::Todo.new(
          id: row[:id],
          account_id: row[:account_id],
          title: row[:title],
          completed: row[:completed],
          created_at: row[:created_at],
          updated_at: row[:updated_at]
        )
      end
    end
  end
end
