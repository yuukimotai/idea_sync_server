# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/usecases/meeting/join_meeting"
require_relative "../../../app/repos/meeting_repository"
require_relative "../../../app/repos/meeting_participant_repository"
require_relative "../../../app/repos/account_repository"
require_relative "../../../lib/hanami_auth_app/jwt_auth"

RSpec.describe HanamiAuthApp::Usecases::Meeting::JoinMeeting do
  let(:account_repo) { HanamiAuthApp::Repos::AccountRepository.new }
  let(:meeting_repo) { HanamiAuthApp::Repos::MeetingRepository.new }
  let(:participant_repo) { HanamiAuthApp::Repos::MeetingParticipantRepository.new }
  let(:usecase) { described_class.new(meeting_repo, participant_repo) }

  let(:owner) do
    account_repo.create("join_owner_#{SecureRandom.hex(6)}@example.com",
                        HanamiAuthApp::JwtAuth.hash_password("password123"))
  end

  let(:guest) do
    account_repo.create("join_guest_#{SecureRandom.hex(6)}@example.com",
                        HanamiAuthApp::JwtAuth.hash_password("password123"))
  end

  let(:meeting) { meeting_repo.create(created_by: owner.id, title: "入室テスト会議", purpose: "brainstorm") }

  it "generates a 12-char room_code and 6-char passcode on create" do
    expect(meeting.room_code).to match(/\A[A-Z0-9]{12}\z/)
    expect(meeting.passcode.length).to eq(6)
  end

  it "joins with correct room_code and passcode" do
    result = usecase.call(account_id: guest.id, room_code: meeting.room_code, passcode: meeting.passcode)

    expect(result.success?).to be true
    expect(result.value[:meeting].id).to eq(meeting.id)
    expect(result.value[:participant].account_id).to eq(guest.id)
  end

  it "is idempotent for repeated joins" do
    first  = usecase.call(account_id: guest.id, room_code: meeting.room_code, passcode: meeting.passcode)
    second = usecase.call(account_id: guest.id, room_code: meeting.room_code, passcode: meeting.passcode)

    expect(second.success?).to be true
    expect(second.value[:participant].id).to eq(first.value[:participant].id)
  end

  it "rejects a wrong passcode" do
    result = usecase.call(account_id: guest.id, room_code: meeting.room_code, passcode: "XXXXXX")

    expect(result.success?).to be false
    expect(result.error).to eq("Meeting not found")
  end

  it "rejects an unknown room_code" do
    result = usecase.call(account_id: guest.id, room_code: "NOSUCHROOM12", passcode: meeting.passcode)

    expect(result.success?).to be false
    expect(result.error).to eq("Meeting not found")
  end

  it "rejects joining a closed meeting" do
    meeting_repo.update_status(meeting.id, "closed")
    result = usecase.call(account_id: guest.id, room_code: meeting.room_code, passcode: meeting.passcode)

    expect(result.success?).to be false
    expect(result.error).to eq("Meeting is closed")
  end
end
