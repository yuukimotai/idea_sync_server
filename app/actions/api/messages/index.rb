# frozen_string_literal: true

require_relative "../../../usecases/message/list_messages"
require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Messages
        class Index < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            usecase = Usecases::Message::ListMessages.new(
              HanamiAuthApp::App.container.resolve(:message_repository)
            )
            result = usecase.call(limit: 50)

            if result.success?
              response.body = { messages: result.value[:messages].map { |msg| message_to_json(msg) } }.to_json
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
