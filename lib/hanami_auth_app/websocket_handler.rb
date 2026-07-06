# frozen_string_literal: true

require "json"
require "set"
require "rack/utils"
require "async/websocket/adapters/rack"
require_relative "jwt_auth"
require_relative "ws_broadcaster"

module HanamiAuthApp
  # WebSocket server for global chat and per-meeting room chat.
  # room_code=xxx in query string → meeting room. omitted → global ("global" key).
  # 配信は broadcaster に委譲する:
  #   REDIS_URL あり → RedisBroadcaster（Falcon --count N の複数プロセス対応）
  #   REDIS_URL なし → LocalBroadcaster（単一プロセス・プロセス内配信のみ）
  class WebsocketHandler
    PATH = "/cable"
    GLOBAL_ROOM = "global"

    # { room_key => Set<connection> }  ※このプロセスが持つ接続のみ
    @connections = Hash.new { |h, k| h[k] = Set.new }
    @mutex = Mutex.new

    class << self
      attr_reader :connections, :mutex
    end

    def initialize(app, message_repository: nil, meeting_repository: nil, broadcaster: nil)
      @app = app
      @message_repository = message_repository
      @meeting_repository = meeting_repository
      @broadcaster = broadcaster || LocalBroadcaster.new
      @broadcaster.on_message { |room_key, json| deliver_local(room_key, json) }
    end

    def call(env)
      return @app.call(env) unless env["PATH_INFO"] == PATH

      account_id = authenticate(env)
      return [401, { "content-type" => "text/plain" }, ["Unauthorized"]] unless account_id

      params    = Rack::Utils.parse_query(env["QUERY_STRING"])
      room_code = params["room_code"]
      room_key  = room_code || GLOBAL_ROOM

      Async::WebSocket::Adapters::Rack.open(env) do |connection|
        handle_connection(connection, account_id, room_key, room_code)
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

    def handle_connection(connection, account_id, room_key, room_code)
      @broadcaster.start # Redis 購読を開始（冪等）。受信専門プロセスにも必要
      self.class.mutex.synchronize { self.class.connections[room_key] << connection }

      meeting_id = resolve_meeting_id(room_code)

      while (message = connection.read)
        data = parse_message(message)
        next unless data

        body = data["body"].to_s.strip
        next if body.empty?

        repo = @message_repository || HanamiAuthApp::App.container.resolve(:message_repository)
        msg  = repo.create(account_id: account_id, body: body, meeting_id: meeting_id)
        broadcast(room_key,
          id:         msg.id,
          account_id: msg.account_id,
          body:       msg.body,
          meeting_id: msg.meeting_id,
          created_at: msg.created_at)
      end
    ensure
      self.class.mutex.synchronize { self.class.connections[room_key].delete(connection) }
    end

    def resolve_meeting_id(room_code)
      return nil unless room_code

      repo = @meeting_repository
      return nil unless repo

      meeting = repo.find_by_room_code(room_code)
      meeting&.id
    end

    def parse_message(message)
      JSON.parse(message.to_str)
    rescue JSON::ParserError
      nil
    end

    # 配信は broadcaster 経由。Redis モードでは全プロセス（自分含む）の
    # deliver_local が呼ばれ、各プロセスが自分の接続にだけ書き込む。
    def broadcast(room_key, payload)
      @broadcaster.publish(room_key, JSON.generate(payload))
    end

    def deliver_local(room_key, json)
      targets = self.class.mutex.synchronize { self.class.connections[room_key].dup }
      targets.each do |conn|
        conn.write(json)
        conn.flush
      rescue StandardError
        self.class.mutex.synchronize { self.class.connections[room_key].delete(conn) }
      end
    end
  end
end
