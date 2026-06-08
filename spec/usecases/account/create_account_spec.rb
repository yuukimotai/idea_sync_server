# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/usecases/account/create_account"
require_relative "../../../app/repos/account_repository"

RSpec.describe "CreateAccount UseCase" do
  let(:account_repo) { HanamiAuthApp::Repos::AccountRepository.new }
  let(:usecase) { HanamiAuthApp::Usecases::Account::CreateAccount.new(account_repo) }

  describe "#call" do
    context "with valid email and password" do
      it "creates account and returns success with token" do
        unique_email = "test_#{Time.now.to_i}@example.com"
        result = usecase.call(email: unique_email, password: "password123")

        expect(result.success?).to be true
        expect(result.value[:account].email).to eq(unique_email)
        expect(result.value[:token]).to be_a(String)
        expect(result.value[:token].split(".").length).to eq(3)
      end
    end

    context "with missing email" do
      it "returns failure" do
        result = usecase.call(email: "", password: "password123")

        expect(result.success?).to be false
        expect(result.error).to include("Email is required")
      end
    end

    context "with missing password" do
      it "returns failure" do
        result = usecase.call(email: "test@example.com", password: "")

        expect(result.success?).to be false
        expect(result.error).to include("Password is required")
      end
    end

    context "with duplicate email" do
      it "returns failure" do
        dup_email = "duplicate_#{Time.now.to_i}@example.com"
        usecase.call(email: dup_email, password: "password123")
        result = usecase.call(email: dup_email, password: "password123")

        expect(result.success?).to be false
        expect(result.error).to include("Email already exists")
      end
    end
  end
end
