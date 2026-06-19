# frozen_string_literal: true

require_relative "../../../../usecases/meeting/assign_role"
require_relative "../../../../../lib/hanami_auth_app/action_auth"
require_relative "../../../../../lib/hanami_auth_app/meeting_serializer"

module HanamiAuthApp
  module Actions
    module API
      module Meetings
        module Roles
          # POST /api/meetings/:id/roles  —  機能ロールの付与（admin のみ）
          class Create < HanamiAuthApp::Action
            include HanamiAuthApp::ActionAuth
            include MeetingSerializer

            def handle(request, response)
              account = authenticate(request, response)
              return unless account

              params = JSON.parse(request.body.read)

              usecase = Usecases::Meeting::AssignRole.new(
                HanamiAuthApp::App.container.resolve(:meeting_repository),
                HanamiAuthApp::App.container.resolve(:meeting_participant_repository),
                HanamiAuthApp::App.container.resolve(:account_repository)
              )
              result = usecase.call(
                account: account,
                meeting_id: request.params[:id],
                target_account_id: params["account_id"],
                role: params["role"]
              )

              if result.success?
                response.status = 201
                response.body = { participant: participant_to_json(result.value[:participant]) }.to_json
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
end
