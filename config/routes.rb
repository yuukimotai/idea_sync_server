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
    get "/api/me", to: "api.me.show"

    # API routes for ideas
    get "/api/ideas", to: "api.ideas.index"
    post "/api/ideas", to: "api.ideas.create"
    get "/api/ideas/:id", to: "api.ideas.show"
    patch "/api/ideas/:id", to: "api.ideas.update"
    delete "/api/ideas/:id", to: "api.ideas.delete"

    # API routes for messages
    get "/api/messages", to: "api.messages.index"
    post "/api/messages", to: "api.messages.create"

    # API routes for AI chat
    get "/api/ai_chat/sessions", to: "api.ai_chat.sessions.get_or_create"
    get "/api/ai_chat/sessions/:session_id/messages", to: "api.ai_chat.messages.index"
    post "/api/ai_chat/sessions/:session_id/messages", to: "api.ai_chat.messages.create"
  end
end
