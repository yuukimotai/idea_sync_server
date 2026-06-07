# frozen_string_literal: true

module HanamiAuthApp
  class Routes < Hanami::Routes
    root to: "home.index"

    get "/todos", to: "todo.index"
    get "/todos/new", to: "todo.create"
    post "/todos", to: "todo.create"

    # API routes for ideas
    get "/api/ideas", to: "api.ideas.index"
    post "/api/ideas", to: "api.ideas.create"
    patch "/api/ideas/:id", to: "api.ideas.update"
    delete "/api/ideas/:id", to: "api.ideas.delete"
  end
end
