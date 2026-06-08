# frozen_string_literal: true

require "hanami"

module HanamiAuthApp
  class App < Hanami::App
    config.root = __dir__.chomp("/config")

    # Require domain layers
    require_relative "../lib/hanami_auth_app/domain/result"
    require_relative "../lib/hanami_auth_app/domain/account/account"
    require_relative "../lib/hanami_auth_app/domain/account/account_repository"
    require_relative "../lib/hanami_auth_app/domain/todo/todo"
    require_relative "../lib/hanami_auth_app/domain/todo/todo_repository"
    require_relative "../lib/hanami_auth_app/domain/idea/idea"
    require_relative "../lib/hanami_auth_app/domain/idea/idea_repository"

    # Register repositories lazily (after RODAUTH_DB is initialized)
    register :todo_repository do
      require_relative "../app/repos/todo_repository"
      HanamiAuthApp::Repos::TodoRepository.new
    end

    register :idea_repository do
      require_relative "../app/repos/idea_repository"
      HanamiAuthApp::Repos::IdeaRepository.new
    end

    register :account_repository do
      require_relative "../app/repos/account_repository"
      HanamiAuthApp::Repos::AccountRepository.new
    end
  end
end

