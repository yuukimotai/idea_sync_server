# frozen_string_literal: true

require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Me
        class Show < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

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
