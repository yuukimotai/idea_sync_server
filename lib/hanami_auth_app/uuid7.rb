# frozen_string_literal: true

require "securerandom"

module HanamiAuthApp
  # UUIDv7 generator (RFC 9562).
  # 先頭48bitにUnixミリ秒タイムスタンプを持つので時系列順にソートでき、
  # PostgreSQLのB-treeインデックスでもランダムなv4のような性能劣化を起こしにくい。
  # PG16にはネイティブの uuidv7() が無いためアプリ側で生成する。
  module Uuid7
    def self.generate
      ms = (Time.now.to_f * 1000).floor
      time_bytes = [ms].pack("Q>")[2, 6] # 48bit big-endian のミリ秒
      buf = (time_bytes + SecureRandom.random_bytes(10)).bytes
      buf[6] = (buf[6] & 0x0F) | 0x70    # version = 7
      buf[8] = (buf[8] & 0x3F) | 0x80    # variant = 10xx
      hex = buf.pack("C*").unpack1("H*")
      "#{hex[0, 8]}-#{hex[8, 4]}-#{hex[12, 4]}-#{hex[16, 4]}-#{hex[20, 12]}"
    end
  end
end
