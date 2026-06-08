# frozen_string_literal: true

require_relative "../../../usecases/message/list_messages"
require_relative "../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module Messages
        class Index < HanamiAuthApp::Action
          def handle(request, response)
            auth_header = request.env["HTTP_AUTHORIZATION"]
            unless auth_header && auth_header.start_with?("Bearer ")
              response.status = 401
              response.body = { error: "Missing or invalid authorization header" }.to_json
              return
            end

            token = auth_header.sub("Bearer ", "")
            payload = JwtAuth.decode(token)

            unless payload
              response.status = 401
              response.body = { error: "Invalid token" }.to_json
              return
            end

            usecase = Usecases::Message::ListMessages.new(
              HanamiAuthApp::App.container.resolve(:message_repository)
            )
            result = usecase.call(limit: 50)

            if result.success?
              messages_json = result.value[:messages].map { |msg| message_to_json(msg) }
              response.body = { messages: messages_json }.to_json
            else
              response.status = 500
              response.body = { error: result.error }.to_json
            end
          end

          private

          def message_to_json(message)
            {
              id: message.id,
              account_id: message.account_id,
              body: message.body,
              created_at: message.created_at
            }
          end
        end
      end
    end
  end
end
