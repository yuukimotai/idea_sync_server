# frozen_string_literal: true

require "json"
require "set"
require "rack/utils"
require "async/websocket/adapters/rack"
require_relative "jwt_auth"

module HanamiAuthApp
  # グローバルチャットの WebSocket。Falcon(async)上で動作する。
  # 認証: httpOnly Cookie の auth_token（JSに出さない）。テスト用に ?token= も許可。
  # ブロードキャスト: プロセス内の接続レジストリ（Falcon --count 1 前提。
  # 複数プロセス化する場合は Redis pub/sub 等が必要）。
  class WebsocketHandler
    PATH = "/cable"

    @connections = Set.new
    @mutex = Mutex.new

    class << self
      attr_reader :connections, :mutex
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      return @app.call(env) unless env["PATH_INFO"] == PATH

      account_id = authenticate(env)
      return [401, { "content-type" => "text/plain" }, ["Unauthorized"]] unless account_id

      Async::WebSocket::Adapters::Rack.open(env) do |connection|
        handle_connection(connection, account_id)
      end || [400, { "content-type" => "text/plain" }, ["Expected WebSocket upgrade"]]
    end

    private

    def authenticate(env)
      token = cookie_value(env["HTTP_COOKIE"], "auth_token")
      token ||= Rack::Utils.parse_query(env["QUERY_STRING"])["token"]
      return nil unless token

      payload = JwtAuth.decode(token)
      payload && payload["account_id"]
    end

    def cookie_value(header, key)
      return nil unless header

      header.split(/;\s*/).each do |pair|
        k, v = pair.split("=", 2)
        return Rack::Utils.unescape(v) if k == key && v
      end
      nil
    end

    def handle_connection(connection, account_id)
      self.class.mutex.synchronize { self.class.connections << connection }

      while (message = connection.read)
        data = parse_message(message)
        next unless data

        body = data["body"].to_s.strip
        next if body.empty?

        msg = HanamiAuthApp::App.container.resolve(:message_repository)
          .create(account_id: account_id, body: body)
        broadcast(
          id: msg.id,
          account_id: msg.account_id,
          body: msg.body,
          created_at: msg.created_at
        )
      end
    ensure
      self.class.mutex.synchronize { self.class.connections.delete(connection) }
    end

    def parse_message(message)
      JSON.parse(message.to_str)
    rescue JSON::ParserError
      nil
    end

    def broadcast(payload)
      json = JSON.generate(payload)
      # await(write)中はロックを持たないよう、スナップショットを取ってから送信する
      targets = self.class.mutex.synchronize { self.class.connections.dup }
      targets.each do |conn|
        conn.write(json)
        conn.flush
      rescue StandardError
        self.class.mutex.synchronize { self.class.connections.delete(conn) }
      end
    end
  end
end
