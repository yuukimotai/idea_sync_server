# frozen_string_literal: true

require_relative "jwt_auth"

module HanamiAuthApp
  class WebsocketHandler
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] == "/chat" && env["rack.upgrade?"]
        handle_websocket(env)
      else
        @app.call(env)
      end
    end

    private

    def handle_websocket(env)
      # Extract JWT from query params
      token = Rack::Utils.parse_query(env["QUERY_STRING"])["token"]

      unless token
        return [401, {}, ["Unauthorized"]]
      end

      payload = JwtAuth.decode(token)
      return [401, {}, ["Invalid token"]] unless payload

      account_id = payload["account_id"]

      # Return Rack WebSocket upgrade response
      env["rack.upgrade"] = proc do |ws|
        handle_connection(ws, account_id)
      end

      [101, { "Upgrade" => "websocket" }, []]
    end

    def handle_connection(ws, account_id)
      # Store active connections
      @connections ||= []
      @connections << ws

      ws.on_message do |msg|
        broadcast_message(account_id, msg, @connections)
      end

      ws.on_close do
        @connections.delete(ws)
      end
    end

    def broadcast_message(account_id, message_body, connections)
      repo = HanamiAuthApp::App.container.resolve(:message_repository)
      msg = repo.create(account_id: account_id, body: message_body)

      # Broadcast to all connected clients
      broadcast_data = {
        id: msg.id,
        account_id: msg.account_id,
        body: msg.body,
        created_at: msg.created_at.to_s
      }

      connections.each do |conn|
        conn.send(broadcast_data.to_json)
      end
    end
  end
end
