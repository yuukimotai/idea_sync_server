# frozen_string_literal: true

require_relative "../../../usecases/idea/delete_idea"
require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Delete < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            usecase = Usecases::Idea::DeleteIdea.new(HanamiAuthApp::App.container.resolve(:idea_repository))
            result = usecase.call(id: request.params[:id], account_id: account.id)

            if result.success?
              response.status = 204
            else
              response.status = error_status(result.error)
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
