# frozen_string_literal: true

require_relative "../../../usecases/idea/update_idea"
require_relative "../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Update < HanamiAuthApp::Action
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

            account_id = payload["account_id"]

            idea_id = request.params[:id]
            params = JSON.parse(request.body.read)

            usecase = Usecases::Idea::UpdateIdea.new(HanamiAuthApp::App.container.resolve(:idea_repository))
            result = usecase.call(
              id: idea_id,
              account_id: account_id,
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

          def error_status(error)
            case error
            when "Forbidden" then 403
            when "Idea not found" then 404
            else 400
            end
          end

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
