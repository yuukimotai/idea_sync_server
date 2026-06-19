# frozen_string_literal: true

require_relative "../../../usecases/meeting/show_meeting"
require_relative "../../../../lib/hanami_auth_app/action_auth"
require_relative "../../../../lib/hanami_auth_app/meeting_serializer"

module HanamiAuthApp
  module Actions
    module API
      module Meetings
        class Show < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth
          include MeetingSerializer

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            usecase = Usecases::Meeting::ShowMeeting.new(
              HanamiAuthApp::App.container.resolve(:meeting_repository),
              HanamiAuthApp::App.container.resolve(:meeting_participant_repository)
            )
            result = usecase.call(account: account, meeting_id: request.params[:id])

            if result.success?
              response.body = {
                meeting: meeting_to_json(result.value[:meeting]),
                participants: result.value[:participants].map { |p| participant_to_json(p) },
                capabilities: result.value[:capabilities]
              }.to_json
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
