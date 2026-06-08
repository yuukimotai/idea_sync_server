# frozen_string_literal: true

module HanamiAuthApp
  class Routes < Hanami::Routes
    root to: "home.index"

    get "/todos", to: "todo.index"
    get "/todos/new", to: "todo.create"
    post "/todos", to: "todo.create"

    # API routes for auth
    post "/api/accounts", to: "api.accounts.create"
    post "/api/login", to: "api.accounts.login"

    # API routes for ideas
    get "/api/ideas", to: "api.ideas.index"
    post "/api/ideas", to: "api.ideas.create"
    get "/api/ideas/:id", to: "api.ideas.show"
    patch "/api/ideas/:id", to: "api.ideas.update"
    delete "/api/ideas/:id", to: "api.ideas.delete"
  end
end
