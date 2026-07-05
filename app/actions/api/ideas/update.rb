# frozen_string_literal: true

require_relative "../../../usecases/idea/update_idea"
require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Update < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            params = JSON.parse(request.body.read)

            usecase = Usecases::Idea::UpdateIdea.new(HanamiAuthApp::App.container.resolve(:idea_repository))
            result = usecase.call(
              id: request.params[:id],
              account_id: account.id,
              title: params["title"],
              description: params["description"]
            )

            if result.success?
              response.body = { idea: idea_to_json(result.value[:idea]) }.to_json
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

          private

          def idea_to_json(idea)
            {
              id: idea.id,
              account_id: idea.account_id,
              title: idea.title,
              description: idea.description,
              created_at: idea.created_at,
              updated_at: idea.updated_at
            }
          end
        end
      end
    end
  end
end
