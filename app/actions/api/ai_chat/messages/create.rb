# frozen_string_literal: true

require_relative "../../../../usecases/ai_chat/send_message"
require_relative "../../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module AiChat
        module Messages
          class Create < HanamiAuthApp::Action
            def handle(request, response)
              payload = authenticate(request, response)
              return unless payload

              session_id = request.params[:session_id]

              begin
                input_data = JSON.parse(request.body.read)
              rescue JSON::ParserError
                response.status = 400
                response.body = { error: "Invalid JSON" }.to_json
                return
              end

              usecase = Usecases::AiChat::SendMessage.new(
                HanamiAuthApp::App.container.resolve(:ai_chat_session_repository),
                HanamiAuthApp::App.container.resolve(:ai_chat_message_repository),
                HanamiAuthApp::App.container.resolve(:idea_repository)
              )
              result = usecase.call(
                account_id: payload["account_id"],
                session_id: session_id,
                body: input_data["body"]
              )

              if result.success?
                response.status = 201
                response.body = {
                  user_message: message_to_json(result.value[:user_message]),
                  ai_message: message_to_json(result.value[:ai_message])
                }.to_json
              else
                status = result.error == "Forbidden" ? 403 : 400
                response.status = status
                response.body = { error: result.error }.to_json
              end
            end

            private

            def authenticate(request, response)
              auth_header = request.env["HTTP_AUTHORIZATION"]
              unless auth_header&.start_with?("Bearer ")
                response.status = 401
                response.body = { error: "Missing or invalid authorization header" }.to_json
                return nil
              end

              payload = JwtAuth.decode(auth_header.sub("Bearer ", ""))
              unless payload
                response.status = 401
                response.body = { error: "Invalid token" }.to_json
                return nil
              end

              payload
            end

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
