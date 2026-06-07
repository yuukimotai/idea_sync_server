# frozen_string_literal: true

require "sequel"
require "roda"

module HanamiAuthApp
  RODAUTH_DB = Sequel.connect(ENV.fetch("DATABASE_URL"))

  class RodauthApp < Roda
    plugin :middleware
    plugin :render, views: File.expand_path("../../../views", __FILE__)

    plugin :rodauth do
      db HanamiAuthApp::RODAUTH_DB
      enable :login, :logout, :create_account

      use_database_authentication_functions? false
      skip_csrf_check? { request.content_type == "application/json" }
    end

    route do |r|
      r.rodauth
    end
  end
end
