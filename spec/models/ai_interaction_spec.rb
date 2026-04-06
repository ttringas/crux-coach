require "rails_helper"

RSpec.describe AiInteraction, type: :model do
  it "is valid with required attributes" do
    interaction = build(:ai_interaction)
    expect(interaction).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it "requires interaction_type" do
      interaction = build(:ai_interaction, interaction_type: nil)
      expect(interaction).not_to be_valid
    end

    it "requires provider" do
      interaction = build(:ai_interaction, provider: nil)
      expect(interaction).not_to be_valid
    end

    it "requires model" do
      interaction = build(:ai_interaction, model: nil)
      expect(interaction).not_to be_valid
    end

    it "requires prompt" do
      interaction = build(:ai_interaction, prompt: nil)
      expect(interaction).not_to be_valid
    end

    it "requires response" do
      interaction = build(:ai_interaction, response: nil)
      expect(interaction).not_to be_valid
    end

    it "requires tokens_used >= 0 when present" do
      interaction = build(:ai_interaction, tokens_used: -1)
      expect(interaction).not_to be_valid
    end

    it "allows nil tokens_used" do
      interaction = build(:ai_interaction, tokens_used: nil)
      expect(interaction).to be_valid
    end
  end

  describe "enums" do
    it "supports expected interaction types" do
      expect(AiInteraction.interaction_types.keys).to contain_exactly(
        "plan_generation", "session_parsing", "profile_analysis", "coach_suggestion"
      )
    end
  end

  describe "scopes" do
    it ".recent orders by created_at descending" do
      old = create(:ai_interaction, created_at: 1.day.ago)
      recent = create(:ai_interaction)
      expect(AiInteraction.recent.first).to eq(recent)
    end
  end
end
