# frozen_string_literal: true

require "json"

module HanamiAuthApp
  # WS ブロードキャストの配送戦略。
  #   LocalBroadcaster : 単一プロセス用。publish をそのままローカル配信に回す。
  #   RedisBroadcaster : 複数プロセス用。Redis pub/sub 経由で全プロセスに配信する。
  #                      発行元プロセスにも Redis から届くため、ローカル直接配信はしない。
  #
  # 使い方（WebsocketHandler 側）:
  #   broadcaster.on_message { |room_key, json| ... ローカル接続へ書き込み ... }
  #   broadcaster.publish(room_key, json)
  class LocalBroadcaster
    def on_message(&block)
      @callback = block
    end

    # 接続受付時に呼ばれる（Redis 版との interface 合わせ。ここでは何もしない）
    def start; end

    def publish(room_key, json)
      @callback&.call(room_key, json)
    end
  end

  class RedisBroadcaster
    CHANNEL = "idea_sync:ws"

    def initialize(url)
      @url = url
      @mutex = Mutex.new
      @started = false
      @callback = nil
    end

    def on_message(&block)
      @callback = block
    end

    # 購読タスクを起動する（冪等）。
    # publish 時だけでなく WS 接続受付時にも呼ぶこと。そうしないと
    # 「受信専門のプロセス」（自分からは一度も publish しないプロセス）が
    # Redis を購読せず、他プロセス発のメッセージを配信できない。
    def start
      ensure_subscriber
    end

    def publish(room_key, json)
      ensure_subscriber
      publish_client.publish(CHANNEL, JSON.generate("room_key" => room_key, "data" => json))
    end

    private

    def endpoint
      require "async/redis"
      Async::Redis::Endpoint.parse(@url)
    end

    def publish_client
      @publish_client ||= begin
        require "async/redis"
        Async::Redis::Client.new(endpoint)
      end
    end

    # 購読タスクは reactor 上で1プロセス1本だけ起動する。
    # WS 接続と同じ reactor で動くため、接続への書き込みが競合しない。
    # transient: リクエストの Async タスクから起動しても reactor 側に付け替えられ、
    # リクエスト終了後も生き続ける。
    def ensure_subscriber
      @mutex.synchronize do
        return if @started
        @started = true
      end

      Async(transient: true, annotation: "redis-ws-subscriber") do
        loop do
          require "async/redis"
          client = Async::Redis::Client.new(endpoint)
          client.subscribe(CHANNEL) do |context|
            while (event = context.listen)
              type, _channel, payload = event
              next unless type == "message"

              begin
                msg = JSON.parse(payload)
                @callback&.call(msg["room_key"], msg["data"])
              rescue JSON::ParserError
                # 不正なペイロードは無視
              end
            end
          end
        rescue StandardError => e
          warn "[ws] Redis subscriber error: #{e.class}: #{e.message} (retrying in 1s)"
          sleep 1
        end
      end
    end
  end
end
