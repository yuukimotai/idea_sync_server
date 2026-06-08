# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/usecases/account/login"
require_relative "../../../app/repos/account_repository"
require_relative "../../../app/usecases/account/create_account"

RSpec.describe "Login UseCase" do
  let(:account_repo) { HanamiAuthApp::Repos::AccountRepository.new }
  let(:login_usecase) { HanamiAuthApp::Usecases::Account::Login.new(account_repo) }
  let(:create_usecase) { HanamiAuthApp::Usecases::Account::CreateAccount.new(account_repo) }

  before do
    create_usecase.call(email: "user@example.com", password: "password123")
  end

  describe "#call" do
    context "with valid credentials" do
      it "returns success with token" do
        result = login_usecase.call(email: "user@example.com", password: "password123")

        expect(result.success?).to be true
        expect(result.value[:account].email).to eq("user@example.com")
        expect(result.value[:token]).to be_a(String)
        expect(result.value[:token].split(".").length).to eq(3)
      end
    end

    context "with invalid email" do
      it "returns failure" do
        result = login_usecase.call(email: "nonexistent@example.com", password: "password123")

        expect(result.success?).to be false
        expect(result.error).to include("Invalid credentials")
      end
    end

    context "with invalid password" do
      it "returns failure" do
        result = login_usecase.call(email: "user@example.com", password: "wrongpassword")

        expect(result.success?).to be false
        expect(result.error).to include("Invalid credentials")
      end
    end

    context "with missing email" do
      it "returns failure" do
        result = login_usecase.call(email: "", password: "password123")

        expect(result.success?).to be false
        expect(result.error).to include("Email is required")
      end
    end

    context "with missing password" do
      it "returns failure" do
        result = login_usecase.call(email: "user@example.com", password: "")

        expect(result.success?).to be false
        expect(result.error).to include("Password is required")
      end
    end
  end
end
