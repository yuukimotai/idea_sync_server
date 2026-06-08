# frozen_string_literal: true

require_relative "../../../usecases/idea/list_ideas"
require_relative "../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
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

            account_id = payload["account_id"]

            usecase = Usecases::Idea::ListIdeas.new(
              HanamiAuthApp::App.container.resolve(:idea_repository)
            )
            result = usecase.call(account_id: account_id)

            if result.success?
              ideas_json = result.value[:ideas].map { |idea| idea_to_json(idea) }
              response.body = { ideas: ideas_json }.to_json
            else
              response.status = 500
              response.body = { error: result.error }.to_json
            end
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
