# frozen_string_literal: true

require "hanami/boot"
require "rack/cors"
require_relative "lib/hanami_auth_app/rewindable_input"

# CORS middleware
use Rack::Cors do
  allow do
    origins "*"
    resource "*", headers: :any, methods: [:get, :post, :patch, :delete, :options]
  end
end

# Falcon の非巻き戻し rack.input 対策（POST/PATCHボディ）
use HanamiAuthApp::RewindableInput

run Hanami.app
