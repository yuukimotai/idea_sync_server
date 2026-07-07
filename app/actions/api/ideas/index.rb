# frozen_string_literal: true

require_relative "../../../usecases/idea/list_ideas"
require_relative "../../../../lib/hanami_auth_app/action_auth"

module HanamiAuthApp
  module Actions
    module API
      module Ideas
        class Index < HanamiAuthApp::Action
          include HanamiAuthApp::ActionAuth

          def handle(request, response)
            account = authenticate(request, response)
            return unless account

            usecase = Usecases::Idea::ListIdeas.new(
              HanamiAuthApp::App.container.resolve(:idea_repository)
            )
            result = usecase.call(
              account_id: account.id,
              q: request.params[:q],
              sort: request.params[:sort],
              order: request.params[:order]
            )

            if result.success?
              response.body = { ideas: result.value[:ideas].map { |idea| idea_to_json(idea) } }.to_json
            else
              response.status = 500
              response.body = { error: result.error }.to_json
            end
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
