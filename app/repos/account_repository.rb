# frozen_string_literal: true

require "sequel"
require_relative "../../lib/hanami_auth_app/uuid7"

module HanamiAuthApp
  module Repos
    class AccountRepository < Domain::Account::AccountRepository
      def initialize(db = nil)
        @db = db || Sequel.connect(ENV.fetch("DATABASE_URL"))
      end

      def find_by_id(id)
        row = @db[:accounts].where(id: id).first
        to_entity(row) if row
      end

      def find_by_email(email)
        row = @db[:accounts].where(email: email).first
        to_entity(row) if row
      end

      def find_by_email_with_password(email)
        @db[:accounts].where(email: email).first
      end

      def create(email, password_digest)
        id = HanamiAuthApp::Uuid7.generate
        @db[:accounts].insert(
          id: id,
          email: email,
          password_digest: password_digest,
          created_at: Time.now,
          updated_at: Time.now
        )
        find_by_id(id)
      end

      def update_role(id, role)
        @db[:accounts].where(id: id).update(role: role, updated_at: Time.now)
        find_by_id(id)
      end

      private

      def to_entity(row)
        Domain::Account::Account.new(
          id: row[:id],
          email: row[:email],
          role: row[:role]
        )
      end
    end
  end
end
