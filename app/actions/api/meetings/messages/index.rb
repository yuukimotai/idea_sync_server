# frozen_string_literal: true

require_relative "../../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Meetings
        module Messages
          class Index < HanamiAuthApp::Action
            include HanamiAuthApp::ActionAuth

            def handle(request, response)
              account = authenticate(request, response)
              return unless account

              meeting_repo = HanamiAuthApp::App.container.resolve(:meeting_repository)
              meeting = meeting_repo.find_by_room_code(request.params[:id]) ||
                        meeting_repo.find_by_id(request.params[:id])

              unless meeting
                response.status = 404
                response.body = { error: "Meeting not found" }.to_json
                return
              end

              message_repo = HanamiAuthApp::App.container.resolve(:message_repository)
              messages = message_repo.list_by_meeting(meeting_id: meeting.id)

              response.body = {
                messages: messages.map { |msg|
                  { id: msg.id, account_id: msg.account_id, body: msg.body,
                    meeting_id: msg.meeting_id, created_at: msg.created_at }
                }
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
end
