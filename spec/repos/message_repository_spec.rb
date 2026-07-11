# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../app/repos/message_repository"
require_relative "../../app/repos/meeting_repository"
require_relative "../../app/repos/account_repository"
require_relative "../../lib/hanami_auth_app/jwt_auth"

RSpec.describe HanamiAuthApp::Repos::MessageRepository do
  let(:account_repo) { HanamiAuthApp::Repos::AccountRepository.new }
  let(:meeting_repo) { HanamiAuthApp::Repos::MeetingRepository.new }
  let(:repo) { described_class.new }

  let(:account) do
    account_repo.create("msg_spec_#{SecureRandom.hex(6)}@example.com",
                        HanamiAuthApp::JwtAuth.hash_password("password123"))
  end

  let(:meeting) do
    meeting_repo.create(created_by: account.id, title: "スコープ検証会議", purpose: "brainstorm")
  end

  describe "meeting_id によるチャンネル分離" do
    it "stores meeting_id and separates meeting messages from global chat" do
      global_msg  = repo.create(account_id: account.id, body: "global message")
      meeting_msg = repo.create(account_id: account.id, body: "meeting message", meeting_id: meeting.id)

      expect(global_msg.meeting_id).to be_nil
      expect(meeting_msg.meeting_id).to eq(meeting.id)

      recent_ids = repo.list_recent(limit: 200).map(&:id)
      expect(recent_ids).to include(global_msg.id)
      expect(recent_ids).not_to include(meeting_msg.id)

      meeting_ids = repo.list_by_meeting(meeting_id: meeting.id).map(&:id)
      expect(meeting_ids).to eq([meeting_msg.id])
    end

    it "does not leak messages between meetings" do
      other_meeting = meeting_repo.create(created_by: account.id, title: "別の会議", purpose: "ideation")
      msg_a = repo.create(account_id: account.id, body: "for A", meeting_id: meeting.id)
      repo.create(account_id: account.id, body: "for B", meeting_id: other_meeting.id)

      ids = repo.list_by_meeting(meeting_id: meeting.id).map(&:id)
      expect(ids).to eq([msg_a.id])
    end

    it "returns messages in chronological order (oldest first)" do
      first  = repo.create(account_id: account.id, body: "first", meeting_id: meeting.id)
      second = repo.create(account_id: account.id, body: "second", meeting_id: meeting.id)

      bodies = repo.list_by_meeting(meeting_id: meeting.id).map(&:id)
      expect(bodies.index(first.id)).to be < bodies.index(second.id)
    end
  end
end
