# frozen_string_literal: true

require "rack/session"
require "hanami/boot"
require_relative "lib/hanami_auth_app/rodauth_app"

use Rack::Session::Cookie,
  key: "_hanami_auth_app_session",
  secret: ENV.fetch("SESSION_SECRET"),
  same_site: :lax,
  max_age: 86_400

use HanamiAuthApp::RodauthApp

run Hanami.app
