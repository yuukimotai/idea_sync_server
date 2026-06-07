# frozen_string_literal: true

require_relative "../../../app/usecases/todo/create_todo"

module HanamiAuthApp
  module Actions
    module Todo
      class Create < HanamiAuthApp::Action
        include Hanami::Action::Session

        def handle(request, response)
          account_id = request.env["rack.session"]&.[](:account_id)

          unless account_id
            response.redirect "/login"
            return
          end

          if request.post?
            title = request.params[:title]
            usecase = Usecases::Todo::CreateTodo.new(container: container)
            result = usecase.call(account_id: account_id, title: title)

            if result.success?
              response.redirect "/todos"
            else
              response.status = 400
              response.body = "Error: #{result.failure}"
            end
          else
            response.body = render_form
          end
        end

        private

        def render_form
          <<~HTML
            <h1>New Todo</h1>
            <form method="post">
              <label>Title: <input type="text" name="title" required /></label>
              <button type="submit">Create</button>
              <a href="/todos">Cancel</a>
            </form>
          HTML
        end
      end
    end
  end
end
