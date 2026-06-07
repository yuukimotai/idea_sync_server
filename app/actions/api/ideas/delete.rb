# frozen_string_literal: true

require_relative "../../../app/usecases/idea/delete_idea"

module HanamiAuthApp
  module Actions
    module Api
      module Ideas
        class Delete < HanamiAuthApp::Action
          include Hanami::Action::Session

          def handle(request, response)
            account_id = request.env["rack.session"]&.[](:account_id)

            unless account_id
              response.status = 401
              response.body = { error: "Unauthorized" }.to_json
              return
            end

            idea_id = request.params[:id]

            usecase = Usecases::Idea::DeleteIdea.new(container: container)
            result = usecase.call(id: idea_id)

            if result.success?
              response.status = 204
            else
              response.status = 400
              response.body = { error: result.failure }.to_json
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
