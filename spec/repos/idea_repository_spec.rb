# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../app/repos/idea_repository"
require_relative "../../app/repos/account_repository"
require_relative "../../lib/hanami_auth_app/jwt_auth"

RSpec.describe HanamiAuthApp::Repos::IdeaRepository do
  let(:account_repo) { HanamiAuthApp::Repos::AccountRepository.new }
  let(:repo) { described_class.new }

  let(:account) do
    account_repo.create("idea_spec_#{SecureRandom.hex(6)}@example.com",
                        HanamiAuthApp::JwtAuth.hash_password("password123"))
  end

  let(:other_account) do
    account_repo.create("idea_spec_other_#{SecureRandom.hex(6)}@example.com",
                        HanamiAuthApp::JwtAuth.hash_password("password123"))
  end

  describe "#list_by_account 検索・並び替え" do
    before do
      repo.create(account_id: account.id, title: "Alpha Redis tuning", description: "cache layer")
      repo.create(account_id: account.id, title: "Beta UI redesign", description: "make it beautiful")
      repo.create(account_id: account.id, title: "Gamma", description: "use redis pub/sub")
      repo.create(account_id: other_account.id, title: "Redis idea of others", description: "not mine")
    end

    it "returns only own ideas" do
      titles = repo.list_by_account(account.id).map(&:title)
      expect(titles).to contain_exactly("Alpha Redis tuning", "Beta UI redesign", "Gamma")
    end

    it "matches title and description case-insensitively" do
      titles = repo.list_by_account(account.id, q: "REDIS").map(&:title)
      expect(titles).to contain_exactly("Alpha Redis tuning", "Gamma")
    end

    it "returns empty when nothing matches" do
      expect(repo.list_by_account(account.id, q: "nonexistent-keyword")).to be_empty
    end

    it "ignores blank queries" do
      expect(repo.list_by_account(account.id, q: "   ").size).to eq(3)
    end

    it "sorts by title ascending" do
      titles = repo.list_by_account(account.id, sort: "title", order: "asc").map(&:title)
      expect(titles).to eq(["Alpha Redis tuning", "Beta UI redesign", "Gamma"])
    end

    it "sorts by created_at descending" do
      titles = repo.list_by_account(account.id, sort: "created_at", order: "desc").map(&:title)
      expect(titles.first).to eq("Gamma")
    end

    it "falls back to created_at for unknown sort columns (no SQL injection)" do
      expect {
        repo.list_by_account(account.id, sort: "id; DROP TABLE ideas;", order: "asc")
      }.not_to raise_error
    end
  end

  describe "LIKE メタ文字のエスケープ" do
    before do
      repo.create(account_id: account.id, title: "進捗100%達成プラン", description: "goal")
      repo.create(account_id: account.id, title: "normal idea", description: "plain")
    end

    it "treats % as a literal character" do
      titles = repo.list_by_account(account.id, q: "100%").map(&:title)
      expect(titles).to contain_exactly("進捗100%達成プラン")
    end

    it "does not let a lone % match everything" do
      titles = repo.list_by_account(account.id, q: "%").map(&:title)
      expect(titles).to contain_exactly("進捗100%達成プラン")
    end
  end
end
