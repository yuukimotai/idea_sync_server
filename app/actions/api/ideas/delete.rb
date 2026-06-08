# frozen_string_literal: true

require_relative "../../../usecases/idea/delete_idea"
require_relative "../../../../lib/hanami_auth_app/jwt_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Delete < HanamiAuthApp::Action
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

            idea_id = request.params[:id]

            usecase = Usecases::Idea::DeleteIdea.new(HanamiAuthApp::App.container.resolve(:idea_repository))
            result = usecase.call(id: idea_id)

            if result.success?
              response.status = 204
            else
              response.status = 400
              response.body = { error: result.error }.to_json
            end
          rescue => e
            response.status = 500
            response.body = { error: e.message }.to_json
          end
        end
      end
    end
  end
end
