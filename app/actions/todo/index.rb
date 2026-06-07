# frozen_string_literal: true

require_relative "../../../app/usecases/todo/list_todos"

module HanamiAuthApp
  module Actions
    module Todo
      class Index < HanamiAuthApp::Action
        include Hanami::Action::Session

        def handle(request, response)
          account_id = request.env["rack.session"]&.[](:account_id)

          unless account_id
            response.redirect "/login"
            return
          end

          usecase = Usecases::Todo::ListTodos.new(container: container)
          result = usecase.call(account_id: account_id)

          if result.success?
            response.body = render_todos(request, result[:todos])
          else
            response.status = 500
            response.body = "Error: #{result.failure}"
          end
        end

        private

        def render_todos(request, todos)
          # Simple HTML table for now
          html = <<~HTML
            <h1>My Todos</h1>
            <a href="/todos/new">+ New Todo</a>
            <table>
              <tr>
                <th>Title</th>
                <th>Status</th>
                <th>Actions</th>
              </tr>
          HTML

          todos.each do |todo|
            status = todo.completed ? "✓ Done" : "○ Pending"
            html += <<~HTML
              <tr>
                <td>#{todo.title}</td>
                <td>#{status}</td>
                <td>
                  <a href="/todos/#{todo.id}/edit">Edit</a>
                  <a href="/todos/#{todo.id}/delete">Delete</a>
                  <form method="post" action="/todos/#{todo.id}/toggle" style="display:inline;">
                    <button type="submit">Toggle</button>
                  </form>
                </td>
              </tr>
            HTML
          end

          html += "</table>"
          html
        end
      end
    end
  end
end
