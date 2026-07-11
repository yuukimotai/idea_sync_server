# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/usecases/meeting/assign_role"
require_relative "../../../app/usecases/meeting/revoke_role"
require_relative "../../../app/repos/meeting_repository"
require_relative "../../../app/repos/meeting_participant_repository"
require_relative "../../../app/repos/account_repository"
require_relative "../../../lib/hanami_auth_app/jwt_auth"

RSpec.describe "Meeting functional roles" do
  let(:account_repo) { HanamiAuthApp::Repos::AccountRepository.new }
  let(:meeting_repo) { HanamiAuthApp::Repos::MeetingRepository.new }
  let(:participant_repo) { HanamiAuthApp::Repos::MeetingParticipantRepository.new }

  let(:assign_usecase) { HanamiAuthApp::Usecases::Meeting::AssignRole.new(meeting_repo, participant_repo, account_repo) }
  let(:revoke_usecase) { HanamiAuthApp::Usecases::Meeting::RevokeRole.new(meeting_repo, participant_repo) }

  let(:admin) do
    acc = account_repo.create("role_admin_#{SecureRandom.hex(6)}@example.com",
                              HanamiAuthApp::JwtAuth.hash_password("password123"))
    account_repo.update_role(acc.id, "admin")
  end

  let(:member) do
    account_repo.create("role_member_#{SecureRandom.hex(6)}@example.com",
                        HanamiAuthApp::JwtAuth.hash_password("password123"))
  end

  let(:meeting) { meeting_repo.create(created_by: admin.id, title: "ロール検証会議", purpose: "refinement") }

  describe "AssignRole" do
    it "assigns a role via room_code (auto-adds non-participant)" do
      result = assign_usecase.call(
        account: admin, meeting_id: meeting.room_code,
        target_account_id: member.id, role: "facilitator"
      )

      expect(result.success?).to be true
      expect(result.value[:participant].roles).to include("facilitator")
    end

    it "assigns a role via meeting UUID" do
      result = assign_usecase.call(
        account: admin, meeting_id: meeting.id,
        target_account_id: member.id, role: "secretary"
      )

      expect(result.success?).to be true
      expect(result.value[:participant].roles).to include("secretary")
    end

    it "is idempotent for duplicate assignment" do
      2.times do
        assign_usecase.call(account: admin, meeting_id: meeting.room_code,
                            target_account_id: member.id, role: "timekeeper")
      end
      participant = participant_repo.find_participation(meeting_id: meeting.id, account_id: member.id)
      expect(participant.roles.count("timekeeper")).to eq(1)
    end

    it "rejects non-admin callers" do
      result = assign_usecase.call(
        account: member, meeting_id: meeting.room_code,
        target_account_id: member.id, role: "facilitator"
      )

      expect(result.success?).to be false
      expect(result.error).to eq("Forbidden")
    end

    it "rejects unknown roles" do
      result = assign_usecase.call(
        account: admin, meeting_id: meeting.room_code,
        target_account_id: member.id, role: "superuser"
      )

      expect(result.success?).to be false
      expect(result.error).to eq("Invalid role")
    end

    it "rejects unknown meetings" do
      result = assign_usecase.call(
        account: admin, meeting_id: "NOSUCHROOM12",
        target_account_id: member.id, role: "facilitator"
      )

      expect(result.success?).to be false
      expect(result.error).to eq("Meeting not found")
    end
  end

  describe "RevokeRole" do
    before do
      assign_usecase.call(account: admin, meeting_id: meeting.room_code,
                          target_account_id: member.id, role: "facilitator")
    end

    it "revokes the role but keeps the participant record" do
      result = revoke_usecase.call(
        account: admin, meeting_id: meeting.room_code,
        target_account_id: member.id, role: "facilitator"
      )

      expect(result.success?).to be true
      expect(result.value[:participant].roles).not_to include("facilitator")
      expect(participant_repo.find_participation(meeting_id: meeting.id, account_id: member.id)).not_to be_nil
    end

    it "rejects non-admin callers" do
      result = revoke_usecase.call(
        account: member, meeting_id: meeting.room_code,
        target_account_id: member.id, role: "facilitator"
      )

      expect(result.success?).to be false
      expect(result.error).to eq("Forbidden")
    end

    it "fails for a non-participant target" do
      outsider = account_repo.create("role_out_#{SecureRandom.hex(6)}@example.com",
                                     HanamiAuthApp::JwtAuth.hash_password("password123"))
      result = revoke_usecase.call(
        account: admin, meeting_id: meeting.room_code,
        target_account_id: outsider.id, role: "facilitator"
      )

      expect(result.success?).to be false
      expect(result.error).to eq("Participant not found")
    end
  end
end
