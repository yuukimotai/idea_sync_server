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
  module Database
    def self.connection
      @connection ||= Sequel.connect(
        ENV.fetch("DATABASE_URL"),
        max_connections: Integer(ENV.fetch("DB_MAX_CONNECTIONS", "10"))
      )
    end
  end
end
