# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/hanami_auth_app/ws_broadcaster"

RSpec.describe HanamiAuthApp::LocalBroadcaster do
  it "delivers published payloads to the registered callback" do
    broadcaster = described_class.new
    received = []
    broadcaster.on_message { |room_key, json| received << [room_key, json] }

    broadcaster.publish("global", '{"body":"hello"}')
    broadcaster.publish("ROOM12345678", '{"body":"room"}')

    expect(received).to eq([
      ["global", '{"body":"hello"}'],
      ["ROOM12345678", '{"body":"room"}']
    ])
  end

  it "does not raise when no callback is registered" do
    expect { described_class.new.publish("global", "{}") }.not_to raise_error
  end

  it "responds to start (interface parity with RedisBroadcaster)" do
    expect { described_class.new.start }.not_to raise_error
  end
end
