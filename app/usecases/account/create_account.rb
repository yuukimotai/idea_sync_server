# frozen_string_literal: true

require_relative "../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Usecases
    module Account
      class CreateAccount
        def initialize(account_repository)
          @account_repository = account_repository
        end

        def call(email:, password:)
          return Domain::Result.err("Email is required") if email.nil? || email.empty?
          return Domain::Result.err("Password is required") if password.nil? || password.empty?

          existing = @account_repository.find_by_email(email)
          return Domain::Result.err("Email already exists") if existing

          password_digest = JwtAuth.hash_password(password)
          account = @account_repository.create(email, password_digest)
          token = JwtAuth.encode(account.id)

          Domain::Result.ok({ account: account, token: token })
        rescue => e
          Domain::Result.err(e.message)
        end
      end
    end
  end
end
