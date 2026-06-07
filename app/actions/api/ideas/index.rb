# frozen_string_literal: true

require_relative "../../../app/usecases/idea/list_ideas"

module HanamiAuthApp
  module Actions
    module Api
      module Ideas
        class Index < HanamiAuthApp::Action
          include Hanami::Action::Session

          def handle(request, response)
            account_id = request.env["rack.session"]&.[](:account_id)

            unless account_id
              response.status = 401
              response.body = { error: "Unauthorized" }.to_json
              return
            end

            usecase = Usecases::Idea::ListIdeas.new(container: container)
            result = usecase.call(account_id: account_id)

            if result.success?
              ideas_json = result[:ideas].map { |idea| idea_to_json(idea) }
              response.body = { ideas: ideas_json }.to_json
            else
              response.status = 500
              response.body = { error: result.failure }.to_json
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
