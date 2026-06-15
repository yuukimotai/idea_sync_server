# frozen_string_literal: true

require_relative "../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module Me
        class Show < HanamiAuthApp::Action
          def handle(request, response)
            auth_header = request.env["HTTP_AUTHORIZATION"]
            unless auth_header && auth_header.start_with?("Bearer ")
              response.status = 401
              response.body = { error: "Missing or invalid authorization header" }.to_json
              return
            end

            token = auth_header.sub("Bearer ", "")
            payload = JwtAuth.decode(token)

            unless payload
              response.status = 401
              response.body = { error: "Invalid token" }.to_json
              return
            end

            account_repo = HanamiAuthApp::App.container.resolve(:account_repository)
            account = account_repo.find_by_id(payload["account_id"])

            unless account
              response.status = 401
              response.body = { error: "Account not found" }.to_json
              return
            end

            response.body = {
              account_id: account.id,
              email: account.email,
              role: account.role
            }.to_json
          rescue => e
            response.status = 500
            response.body = { error: e.message }.to_json
          end
        end
      end
    end
  end
end
