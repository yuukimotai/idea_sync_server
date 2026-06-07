# frozen_string_literal: true

require_relative "../../../app/usecases/idea/create_idea"

module HanamiAuthApp
  module Actions
    module Api
      module Ideas
        class Create < HanamiAuthApp::Action
          include Hanami::Action::Session

          def handle(request, response)
            account_id = request.env["rack.session"]&.[](:account_id)

            unless account_id
              response.status = 401
              response.body = { error: "Unauthorized" }.to_json
              return
            end

            params = JSON.parse(request.body.read)

            usecase = Usecases::Idea::CreateIdea.new(container: container)
            result = usecase.call(
              account_id: account_id,
              title: params["title"],
              description: params["description"] || ""
            )

            if result.success?
              response.status = 201
              response.body = { idea: idea_to_json(result[:idea]) }.to_json
            else
              response.status = 400
              response.body = { error: result.failure }.to_json
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
