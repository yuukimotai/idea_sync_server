# frozen_string_literal: true

# Standalone WebSocket process entry point.
# Boots the minimal stack (DB + JWT + MessageRepository) without loading Hanami.
# Run with: bundle exec falcon serve --count 1 --bind tcp://localhost:3001 --config cable.ru

begin
  require "dotenv/load"
rescue LoadError
  # not installed in production; env vars set externally
end

require "sequel"
require_relative "lib/hanami_auth_app/database"
require_relative "lib/hanami_auth_app/domain/message/message"
require_relative "lib/hanami_auth_app/domain/message/message_repository"
require_relative "lib/hanami_auth_app/domain/meeting/meeting"
require_relative "lib/hanami_auth_app/domain/meeting/meeting_repository"
require_relative "lib/hanami_auth_app/uuid7"
require_relative "app/repos/message_repository"
require_relative "app/repos/meeting_repository"
require_relative "lib/hanami_auth_app/jwt_auth"
require_relative "lib/hanami_auth_app/websocket_handler"

message_repo = HanamiAuthApp::Repos::MessageRepository.new
meeting_repo = HanamiAuthApp::Repos::MeetingRepository.new

NOT_FOUND = proc { [404, { "content-type" => "text/plain" }, ["Not Found"]] }.freeze

run HanamiAuthApp::WebsocketHandler.new(NOT_FOUND, message_repository: message_repo, meeting_repository: meeting_repo)
