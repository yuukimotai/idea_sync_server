# frozen_string_literal: true

require_relative "../../../usecases/meeting/join_meeting"
require_relative "../../../../lib/hanami_auth_app/action_auth"
require_relative "../../../../lib/hanami_auth_app/meeting_serializer"

module HanamiAuthApp
  module Actions
    module API
      module Meetings
        class Join < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth
          include MeetingSerializer

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            params = JSON.parse(request.body.read)

            usecase = Usecases::Meeting::JoinMeeting.new(
              HanamiAuthApp::App.container.resolve(:meeting_repository),
              HanamiAuthApp::App.container.resolve(:meeting_participant_repository)
            )
            result = usecase.call(
              account_id: account.id,
              meeting_id: request.params[:id],
              passcode: params["passcode"].to_s.strip.upcase
            )

            if result.success?
              response.status = 200
              response.body = {
                meeting: meeting_to_json(result.value[:meeting]),
                participant: participant_to_json(result.value[:participant])
              }.to_json
            else
              response.status = error_status(result.error)
              response.body = { error: result.error }.to_json
            end
          rescue JSON::ParserError
            response.status = 400
            response.body = { error: "Invalid JSON" }.to_json
          rescue => e
            response.status = 500
            response.body = { error: e.message }.to_json
          end
        end
      end
    end
  end
end
