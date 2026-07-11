# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/hanami_auth_app/domain/account/account"
require_relative "../../lib/hanami_auth_app/domain/meeting/meeting_participant"
require_relative "../../lib/hanami_auth_app/domain/meeting/meeting_policy"

RSpec.describe HanamiAuthApp::Domain::Meeting::MeetingPolicy do
  def account(role: "user")
    HanamiAuthApp::Domain::Account::Account.new(id: "acc-1", email: "a@example.com", role: role)
  end

  def participant(roles: [])
    HanamiAuthApp::Domain::Meeting::MeetingParticipant.new(
      id: "part-1", meeting_id: "m-1", account_id: "acc-1", roles: roles
    )
  end

  describe "#can_view?" do
    it "allows participants" do
      policy = described_class.new(account: account, participant: participant)
      expect(policy.can_view?).to be true
    end

    it "allows admin even without participation" do
      policy = described_class.new(account: account(role: "admin"), participant: nil)
      expect(policy.can_view?).to be true
    end

    it "denies non-participant non-admin" do
      policy = described_class.new(account: account, participant: nil)
      expect(policy.can_view?).to be false
    end
  end

  describe "functional roles" do
    it "facilitator can progress meeting but not control timer" do
      policy = described_class.new(account: account, participant: participant(roles: ["facilitator"]))
      expect(policy.can_progress_meeting?).to be true
      expect(policy.can_control_timer?).to be false
    end

    it "timekeeper can control timer" do
      policy = described_class.new(account: account, participant: participant(roles: ["timekeeper"]))
      expect(policy.can_control_timer?).to be true
      expect(policy.can_progress_meeting?).to be false
    end

    it "secretary can edit minutes" do
      policy = described_class.new(account: account, participant: participant(roles: ["secretary"]))
      expect(policy.can_edit_minutes?).to be true
    end

    it "presenter can control presentation" do
      policy = described_class.new(account: account, participant: participant(roles: ["presenter"]))
      expect(policy.can_control_presentation?).to be true
    end

    it "participant without roles has view only" do
      policy = described_class.new(account: account, participant: participant)
      expect(policy.can_view?).to be true
      expect(policy.can_progress_meeting?).to be false
      expect(policy.can_control_timer?).to be false
      expect(policy.can_edit_minutes?).to be false
      expect(policy.can_control_presentation?).to be false
    end

    it "supports multiple roles on one participant" do
      policy = described_class.new(account: account, participant: participant(roles: %w[facilitator secretary]))
      expect(policy.can_progress_meeting?).to be true
      expect(policy.can_edit_minutes?).to be true
    end
  end

  describe "#can_manage_roles?" do
    it "allows admin only" do
      expect(described_class.new(account: account(role: "admin"), participant: nil).can_manage_roles?).to be true
      expect(described_class.new(account: account, participant: participant(roles: ["facilitator"])).can_manage_roles?).to be false
    end
  end

  describe "#capabilities" do
    it "returns all capability keys" do
      caps = described_class.new(account: account, participant: participant).capabilities
      expect(caps.keys).to contain_exactly(
        :view, :progress_meeting, :control_timer, :edit_minutes, :control_presentation, :manage_roles
      )
    end
  end
end
