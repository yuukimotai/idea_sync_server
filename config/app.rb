# frozen_string_literal: true

require "hanami"

module HanamiAuthApp
  class App < Hanami::App
    config.root = __dir__.chomp("/config")

    # Require domain and infra layers
    require_relative "../lib/hanami_auth_app/domain/result"
    require_relative "../lib/hanami_auth_app/domain/account/account"
    require_relative "../lib/hanami_auth_app/domain/account/account_repository"
    require_relative "../lib/hanami_auth_app/domain/todo/todo"
    require_relative "../lib/hanami_auth_app/domain/todo/todo_repository"
    require_relative "../lib/hanami_auth_app/domain/idea/idea"
    require_relative "../lib/hanami_auth_app/domain/idea/idea_repository"
    require_relative "../app/repos/todo_repository"
    require_relative "../app/repos/idea_repository"

    # Register services in container
    register :todo_repository, HanamiAuthApp::Repos::TodoRepository.new
    register :idea_repository, HanamiAuthApp::Repos::IdeaRepository.new
  end
end

