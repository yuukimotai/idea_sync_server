# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/hanami_auth_app/jwt_auth"

RSpec.describe HanamiAuthApp::JwtAuth do
  describe ".encode / .decode" do
    it "roundtrips account_id" do
      token = described_class.encode("acc-123")
      payload = described_class.decode(token)

      expect(payload).not_to be_nil
      expect(payload["account_id"]).to eq("acc-123")
    end

    it "produces three dot-separated segments" do
      expect(described_class.encode("acc-123").split(".").length).to eq(3)
    end

    it "rejects a tampered payload" do
      header, payload, signature = described_class.encode("acc-123").split(".")
      forged_payload = described_class.base64_url_encode(
        JSON.generate("account_id" => "acc-evil", "iat" => Time.now.to_i)
      )
      expect(described_class.decode([header, forged_payload, signature].join("."))).to be_nil
    end

    it "rejects a tampered signature" do
      header, payload, _signature = described_class.encode("acc-123").split(".")
      expect(described_class.decode([header, payload, "invalid-signature"].join("."))).to be_nil
    end

    it "rejects garbage input" do
      expect(described_class.decode("not-a-token")).to be_nil
      expect(described_class.decode("")).to be_nil
      expect(described_class.decode(nil)).to be_nil
    end
  end

  describe ".hash_password / .verify_password" do
    it "verifies the correct password" do
      digest = described_class.hash_password("password123")
      expect(described_class.verify_password(digest, "password123")).to be true
    end

    it "rejects a wrong password" do
      digest = described_class.hash_password("password123")
      expect(described_class.verify_password(digest, "wrong")).to be false
    end
  end
end
