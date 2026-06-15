# frozen_string_literal: true

require_relative "../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Show < HanamiAuthApp::Action
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
            idea_repo = HanamiAuthApp::App.container.resolve(:idea_repository)
            idea = idea_repo.find_by_id(idea_id)

            unless idea
              response.status = 404
              response.body = { error: "Idea not found" }.to_json
              return
            end

            unless idea.account_id == account_id
              response.status = 403
              response.body = { error: "Forbidden" }.to_json
              return
            end

            response.body = idea_to_json(idea).to_json
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
