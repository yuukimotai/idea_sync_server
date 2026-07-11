# frozen_string_literal: true

require "base64"
require "json"
require "openssl"
require "bcrypt"

module HanamiAuthApp
  class JwtAuth
    SECRET = ENV.fetch("JWT_SECRET", "dev-secret-key-change-in-production")
    ALGORITHM = "HS256"

    def self.encode(account_id)
      header = { alg: ALGORITHM, typ: "JWT" }
      payload = { account_id: account_id, iat: Time.now.to_i }

      header_json = JSON.generate(header)
      payload_json = JSON.generate(payload)

      header_b64 = base64_url_encode(header_json)
      payload_b64 = base64_url_encode(payload_json)

      message = "#{header_b64}.#{payload_b64}"
      signature = OpenSSL::HMAC.digest("SHA256", SECRET, message)
      signature_b64 = base64_url_encode(signature)

      "#{message}.#{signature_b64}"
    end

    def self.decode(token)
      return nil unless token.is_a?(String)

      parts = token.split(".")
      return nil if parts.length != 3

      header_b64, payload_b64, signature_b64 = parts

      begin
        payload_json = base64_url_decode(payload_b64)
        payload = JSON.parse(payload_json)

        message = "#{header_b64}.#{payload_b64}"
        expected_signature = OpenSSL::HMAC.digest("SHA256", SECRET, message)
        expected_signature_b64 = base64_url_encode(expected_signature)

        return payload if signature_b64 == expected_signature_b64
      rescue
        return nil
      end

      nil
    end

    def self.hash_password(password)
      BCrypt::Password.create(password)
    end

    def self.verify_password(hashed, password)
      BCrypt::Password.new(hashed) == password
    rescue BCrypt::Errors::InvalidHash
      false
    end

    private

    def self.base64_url_encode(str)
      Base64.urlsafe_encode64(str).delete("=")
    end

    def self.base64_url_decode(str)
      # Add padding if needed
      remainder = str.length % 4
      padding = remainder == 0 ? 0 : 4 - remainder
      str_padded = str + ("=" * padding)
      Base64.urlsafe_decode64(str_padded)
    end
  end
end
