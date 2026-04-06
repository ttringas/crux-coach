require "rails_helper"

RSpec.describe Ai::Client do
  let(:user) { create(:user) }
  let(:provider_response) do
    {
      content: '{"result": "ok"}',
      tokens_used: 100,
      input_tokens: 60,
      output_tokens: 40,
      model: "claude-sonnet-4-20250514",
      provider: "anthropic"
    }
  end

  before do
    Rails.configuration.x.ai.enabled = true
    Rails.configuration.x.ai.provider = "anthropic"
    Rails.configuration.x.ai.models = { "anthropic" => "claude-sonnet-4-20250514", "openai" => "gpt-4o" }
    Rails.configuration.x.ai.pricing = nil
    Rails.configuration.x.ai.daily_budget_cents = nil
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("sk-test-key")
    allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("sk-test-key")
  end

  describe ".generate" do
    it "routes to Anthropic provider when configured" do
      allow(Ai::Providers::Anthropic).to receive(:generate).and_return(provider_response)

      described_class.generate(
        prompt: "Hello",
        user: user,
        interaction_type: :plan_generation
      )

      expect(Ai::Providers::Anthropic).to have_received(:generate).with(
        prompt: "Hello",
        system: nil,
        model: "claude-sonnet-4-20250514",
        max_tokens: nil
      )
    end

    it "routes to OpenAI provider when configured" do
      Rails.configuration.x.ai.provider = "openai"
      openai_response = provider_response.merge(provider: "openai", model: "gpt-4o")
      allow(Ai::Providers::OpenAi).to receive(:generate).and_return(openai_response)

      described_class.generate(
        prompt: "Hello",
        user: user,
        interaction_type: :plan_generation
      )

      expect(Ai::Providers::OpenAi).to have_received(:generate)
    end

    it "logs the AI interaction to the database" do
      allow(Ai::Providers::Anthropic).to receive(:generate).and_return(provider_response)

      expect {
        described_class.generate(
          prompt: "Hello",
          user: user,
          interaction_type: :plan_generation
        )
      }.to change(AiInteraction, :count).by(1)

      interaction = AiInteraction.last
      expect(interaction.user).to eq(user)
      expect(interaction.interaction_type).to eq("plan_generation")
      expect(interaction.provider).to eq("anthropic")
      expect(interaction.tokens_used).to eq(100)
    end

    it "returns an OpenStruct with content and metadata" do
      allow(Ai::Providers::Anthropic).to receive(:generate).and_return(provider_response)

      result = described_class.generate(
        prompt: "Hello",
        user: user,
        interaction_type: :plan_generation
      )

      expect(result.content).to eq('{"result": "ok"}')
      expect(result.tokens_used).to eq(100)
      expect(result.model).to eq("claude-sonnet-4-20250514")
      expect(result.provider).to eq("anthropic")
      expect(result.duration_ms).to be_a(Integer)
    end

    it "raises error when usage guard fails" do
      Rails.configuration.x.ai.enabled = false

      expect {
        described_class.generate(
          prompt: "Hello",
          user: user,
          interaction_type: :plan_generation
        )
      }.to raise_error(Ai::Client::Error, /AI features are temporarily unavailable/)
    end

    it "raises error for unknown provider" do
      expect {
        described_class.generate(
          prompt: "Hello",
          user: user,
          interaction_type: :plan_generation,
          provider: "unknown"
        )
      }.to raise_error(Ai::Client::Error, /Unknown AI provider/)
    end

    it "raises ArgumentError when user is nil" do
      expect {
        described_class.generate(prompt: "Hello", user: nil, interaction_type: :plan_generation)
      }.to raise_error(ArgumentError, /user is required/)
    end

    it "raises ArgumentError when interaction_type is nil" do
      expect {
        described_class.generate(prompt: "Hello", user: user, interaction_type: nil)
      }.to raise_error(ArgumentError, /interaction_type is required/)
    end

    it "still logs the interaction when the provider raises an error" do
      allow(Ai::Providers::Anthropic).to receive(:generate)
        .and_raise(Ai::Client::Error.new("API failure", provider: "anthropic"))

      expect {
        described_class.generate(
          prompt: "Hello",
          user: user,
          interaction_type: :plan_generation
        ) rescue nil
      }.to change(AiInteraction, :count).by(1)

      interaction = AiInteraction.last
      expect(interaction.response).to include("ERROR")
    end
  end
end
