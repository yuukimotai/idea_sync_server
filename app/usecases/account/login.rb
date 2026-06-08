# frozen_string_literal: true

require_relative "../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Usecases
    module Account
      class Login
        def initialize(account_repository)
          @account_repository = account_repository
        end

        def call(email:, password:)
          return Domain::Result.err("Email is required") if email.nil? || email.empty?
          return Domain::Result.err("Password is required") if password.nil? || password.empty?

          account_row = @account_repository.find_by_email_with_password(email)
          return Domain::Result.err("Invalid credentials") unless account_row

          is_valid = JwtAuth.verify_password(account_row[:password_digest], password)
          return Domain::Result.err("Invalid credentials") unless is_valid

          token = JwtAuth.encode(account_row[:id])
          account = @account_repository.find_by_id(account_row[:id])

          Domain::Result.ok({ account: account, token: token })
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
