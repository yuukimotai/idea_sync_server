# frozen_string_literal: true

require "hanami/boot"
require_relative "lib/hanami_auth_app/websocket_handler"

use HanamiAuthApp::WebsocketHandler

run Hanami.app
