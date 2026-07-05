# frozen_string_literal: true

require_relative "../../../usecases/message/create_message"
require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Messages
        class Create < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            input_data = JSON.parse(request.body.read)

            usecase = Usecases::Message::CreateMessage.new(
              HanamiAuthApp::App.container.resolve(:message_repository)
            )
            result = usecase.call(account_id: account.id, body: input_data["body"])

            if result.success?
              response.status = 201
              response.body = message_to_json(result.value[:message]).to_json
            else
              response.status = 400
              response.body = { error: result.error }.to_json
            end
          rescue JSON::ParserError
            response.status = 400
            response.body = { error: "Invalid JSON" }.to_json
          rescue => e
            response.status = 500
            response.body = { error: e.message }.to_json
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
