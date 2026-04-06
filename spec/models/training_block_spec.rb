require "rails_helper"

RSpec.describe TrainingBlock, type: :model do
  it "is valid with required attributes" do
    block = build(:training_block)
    expect(block).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:climber_profile) }
    it { is_expected.to have_many(:weekly_plans).dependent(:destroy) }
  end

  describe "validations" do
    it "requires a name" do
      block = build(:training_block, name: nil)
      expect(block).not_to be_valid
      expect(block.errors[:name]).to be_present
    end

    it "requires a focus" do
      block = build(:training_block, focus: nil)
      expect(block).not_to be_valid
    end

    it "requires a status" do
      block = build(:training_block, status: nil)
      expect(block).not_to be_valid
    end

    it "requires weeks_planned > 0 when present" do
      block = build(:training_block, weeks_planned: 0)
      expect(block).not_to be_valid
    end

    it "requires weeks_planned <= 12 when present" do
      block = build(:training_block, weeks_planned: 13)
      expect(block).not_to be_valid
    end

    it "allows nil weeks_planned" do
      block = build(:training_block, weeks_planned: nil)
      expect(block).to be_valid
    end

    it "requires week_number > 0 when present" do
      block = build(:training_block, week_number: 0)
      expect(block).not_to be_valid
    end
  end

  describe "enums" do
    it "supports expected focus types" do
      focus_values = TrainingBlock.defined_enums["focus"]
      expect(focus_values.keys).to include("power", "endurance", "base", "deload")
    end

    it "supports active, completed, and abandoned statuses" do
      expect(TrainingBlock.statuses.keys).to contain_exactly("active", "completed", "abandoned")
    end
  end

  describe "scopes" do
    it ".current returns active blocks" do
      active = create(:training_block, status: :active)
      completed = create(:training_block, status: :completed)
      expect(TrainingBlock.current).to include(active)
      expect(TrainingBlock.current).not_to include(completed)
    end
  end
end
