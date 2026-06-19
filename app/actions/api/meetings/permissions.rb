# frozen_string_literal: true

require_relative "../../../usecases/meeting/meeting_permissions"
require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Meetings
        class Permissions < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            usecase = Usecases::Meeting::MeetingPermissions.new(
              HanamiAuthApp::App.container.resolve(:meeting_repository),
              HanamiAuthApp::App.container.resolve(:meeting_participant_repository)
            )
            result = usecase.call(account: account, meeting_id: request.params[:id])

            if result.success?
              response.body = { capabilities: result.value[:capabilities] }.to_json
            else
              response.status = error_status(result.error)
              response.body = { error: result.error }.to_json
            end
          rescue => e
            response.status = 500
            response.body = { error: e.message }.to_json
          end
        end
      end
    end
  end
end
