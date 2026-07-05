# frozen_string_literal: true

require_relative "../../../../usecases/ai_chat/get_or_create_session"
require_relative "../../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module AiChat
        module Sessions
          class GetOrCreate < HanamiAuthApp::Action
            include HanamiAuthApp::ActionAuth

            def handle(request, response)
              account = authenticate(request, response)
              return unless account

              idea_id = request.params[:idea_id]
              unless idea_id
                response.status = 400
                response.body = { error: "idea_id is required" }.to_json
                return
              end

              usecase = Usecases::AiChat::GetOrCreateSession.new(
                HanamiAuthApp::App.container.resolve(:ai_chat_session_repository),
                HanamiAuthApp::App.container.resolve(:idea_repository)
              )
              result = usecase.call(account_id: account.id, idea_id: idea_id)

              if result.success?
                session = result.value[:session]
                idea    = result.value[:idea]
                response.body = {
                  session: session_to_json(session),
                  idea: { id: idea.id, title: idea.title, description: idea.description }
                }.to_json
              else
                response.status = error_status(result.error)
                response.body = { error: result.error }.to_json
              end
            end

            private

            def session_to_json(session)
              {
                id: session.id,
                account_id: session.account_id,
                idea_id: session.idea_id,
                created_at: session.created_at
              }
            end
          end
        end
      end
    end
  end
end
