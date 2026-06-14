# frozen_string_literal: true

require "sequel"

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
        result = @db[:accounts].insert(
          email: email,
          password_digest: password_digest,
          created_at: Time.now,
          updated_at: Time.now
        )
        find_by_id(result)
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
