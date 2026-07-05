# frozen_string_literal: true

require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Show < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            idea = HanamiAuthApp::App.container.resolve(:idea_repository).find_by_id(request.params[:id])

            unless idea
              response.status = 404
              response.body = { error: "Idea not found" }.to_json
              return
            end

            unless idea.account_id == account.id
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
