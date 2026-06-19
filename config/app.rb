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
    require_relative "../lib/hanami_auth_app/domain/message/message"
    require_relative "../lib/hanami_auth_app/domain/message/message_repository"
    require_relative "../lib/hanami_auth_app/domain/ai_chat/ai_chat_session"
    require_relative "../lib/hanami_auth_app/domain/ai_chat/ai_chat_message"
    require_relative "../lib/hanami_auth_app/domain/ai_chat/ai_chat_session_repository"
    require_relative "../lib/hanami_auth_app/domain/ai_chat/ai_chat_message_repository"
    require_relative "../lib/hanami_auth_app/domain/meeting/meeting"
    require_relative "../lib/hanami_auth_app/domain/meeting/meeting_participant"
    require_relative "../lib/hanami_auth_app/domain/meeting/meeting_policy"
    require_relative "../lib/hanami_auth_app/domain/meeting/meeting_repository"
    require_relative "../lib/hanami_auth_app/domain/meeting/meeting_participant_repository"

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

    register :message_repository do
      require_relative "../app/repos/message_repository"
      HanamiAuthApp::Repos::MessageRepository.new
    end

    register :ai_chat_session_repository do
      require_relative "../app/repos/ai_chat_session_repository"
      HanamiAuthApp::Repos::AiChatSessionRepository.new
    end

    register :ai_chat_message_repository do
      require_relative "../app/repos/ai_chat_message_repository"
      HanamiAuthApp::Repos::AiChatMessageRepository.new
    end

    register :meeting_repository do
      require_relative "../app/repos/meeting_repository"
      HanamiAuthApp::Repos::MeetingRepository.new
    end

    register :meeting_participant_repository do
      require_relative "../app/repos/meeting_participant_repository"
      HanamiAuthApp::Repos::MeetingParticipantRepository.new
    end
  end
end

