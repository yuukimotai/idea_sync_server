# frozen_string_literal: true

require_relative "../../../../usecases/ai_chat/list_messages"
require_relative "../../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module AiChat
        module Messages
          class Index < HanamiAuthApp::Action
            include HanamiAuthApp::ActionAuth

            def handle(request, response)
              account = authenticate(request, response)
              return unless account

              usecase = Usecases::AiChat::ListMessages.new(
                HanamiAuthApp::App.container.resolve(:ai_chat_session_repository),
                HanamiAuthApp::App.container.resolve(:ai_chat_message_repository)
              )
              result = usecase.call(account_id: account.id, session_id: request.params[:session_id])

              if result.success?
                response.body = { messages: result.value[:messages].map { |m| message_to_json(m) } }.to_json
              else
                response.status = error_status(result.error)
                response.body = { error: result.error }.to_json
              end
            end

            private

            def message_to_json(message)
              {
                id: message.id,
                session_id: message.session_id,
                role: message.role,
                body: message.body,
                created_at: message.created_at
              }
            end
          end
        end
      end
    end
  end
end
