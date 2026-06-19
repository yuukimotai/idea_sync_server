# frozen_string_literal: true

require_relative "../../../usecases/meeting/list_meetings"
require_relative "../../../../lib/hanami_auth_app/action_auth"
require_relative "../../../../lib/hanami_auth_app/meeting_serializer"

module HanamiAuthApp
  module Actions
    module API
      module Meetings
        class Index < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth
          include MeetingSerializer

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            usecase = Usecases::Meeting::ListMeetings.new(
              HanamiAuthApp::App.container.resolve(:meeting_repository)
            )
            result = usecase.call(account: account)

            if result.success?
              meetings = result.value[:meetings].map { |m| meeting_to_json(m) }
              response.body = { meetings: meetings }.to_json
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
