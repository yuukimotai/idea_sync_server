# frozen_string_literal: true

require "sequel"

module HanamiAuthApp
  # アプリ全体で共有する単一の Sequel 接続（＝単一プール）。
  #
  # 以前は各リポジトリの initialize で Sequel.connect していたが、
  # DIコンテナはリポジトリを resolve の度に生成する（ファクトリ）ため、
  # リクエストごとに新しい接続プールが作られて閉じられず、
  # PostgreSQL の接続上限（too many clients）に達していた。
  # ここで一度だけ接続を張り、全リポジトリで使い回す。
  # Falcon(async) では複数 fiber が同時にクエリを投げる。
  # 素の Sequel はスレッド単位でしか接続を分けないため、同一スレッド内の
  # fiber 同士が1本の PG 接続を共有して壊れる（nfields for nil 等）。
  # fiber 単位でプールから接続を取り分けるよう拡張する（Puma 下でも無害）。
  Sequel.extension(:fiber_concurrency)

  module Database
    def self.connection
      @connection ||= Sequel.connect(
        ENV.fetch("DATABASE_URL"),
        max_connections: Integer(ENV.fetch("DB_MAX_CONNECTIONS", "10"))
      )
    end
  end
end
