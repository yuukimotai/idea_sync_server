# frozen_string_literal: true

require "hanami/boot"
require "rack/cors"
require_relative "lib/hanami_auth_app/websocket_handler"

# CORS middleware
use Rack::Cors do
  allow do
    origins "*"
    resource "*", headers: :any, methods: [:get, :post, :patch, :delete, :options]
  end
end

use HanamiAuthApp::WebsocketHandler

run Hanami.app
