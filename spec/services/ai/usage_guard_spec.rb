require "rails_helper"

RSpec.describe Ai::UsageGuard do
  let(:user) { create(:user) }

  before do
    Rails.configuration.x.ai.enabled = true
    Rails.configuration.x.ai.provider = "anthropic"
    Rails.configuration.x.ai.daily_budget_cents = nil
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("sk-test-key")
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test-key")
  end

  describe ".check!" do
    it "passes when under all limits" do
      expect {
        described_class.check!(user: user, interaction_type: :plan_generation, provider: "anthropic")
      }.not_to raise_error
    end

    it "raises error when daily total call limit is exceeded" do
      create_list(:ai_interaction, Ai::UsageGuard::TOTAL_LIMIT_PER_DAY, user: user)

      expect {
        described_class.check!(user: user, interaction_type: :plan_generation, provider: "anthropic")
      }.to raise_error(Ai::Client::Error, /Daily AI usage limit reached/)
    end

    it "raises error when plan_generation limit is exceeded" do
      create_list(:ai_interaction, Ai::UsageGuard::PLAN_LIMIT_PER_DAY,
                  user: user, interaction_type: :plan_generation)

      expect {
        described_class.check!(user: user, interaction_type: :plan_generation, provider: "anthropic")
      }.to raise_error(Ai::Client::Error, /Daily plan generation limit reached/)
    end

    it "raises error when session_parsing limit is exceeded" do
      create_list(:ai_interaction, Ai::UsageGuard::SESSION_LIMIT_PER_DAY,
                  user: user, interaction_type: :session_parsing)

      expect {
        described_class.check!(user: user, interaction_type: :session_parsing, provider: "anthropic")
      }.to raise_error(Ai::Client::Error, /Daily session parsing limit reached/)
    end

    it "raises error when AI features are disabled" do
      Rails.configuration.x.ai.enabled = false

      expect {
        described_class.check!(user: user, interaction_type: :plan_generation, provider: "anthropic")
      }.to raise_error(Ai::Client::Error, /AI features are temporarily unavailable/)
    end

    it "raises error when API key is missing" do
      allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil)

      expect {
        described_class.check!(user: user, interaction_type: :plan_generation, provider: "anthropic")
      }.to raise_error(Ai::Client::Error, /API key is missing/)
    end

    it "raises error when daily budget is exceeded" do
      Rails.configuration.x.ai.daily_budget_cents = 100
      create(:ai_interaction, user: user, cost_cents: 150)

      expect {
        described_class.check!(user: user, interaction_type: :plan_generation, provider: "anthropic")
      }.to raise_error(Ai::Client::Error, /Daily AI budget exceeded/)
    end
  end
end
