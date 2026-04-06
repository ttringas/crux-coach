require "rails_helper"

RSpec.describe WeeklyPlan, type: :model do
  it "is valid with required attributes" do
    plan = build(:weekly_plan)
    expect(plan).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:training_block) }
    it { is_expected.to belong_to(:climber_profile) }
    it { is_expected.to have_many(:planned_sessions).dependent(:destroy) }
  end

  describe "validations" do
    it "requires week_of" do
      plan = build(:weekly_plan, week_of: nil)
      expect(plan).not_to be_valid
      expect(plan.errors[:week_of]).to be_present
    end

    it "requires status" do
      plan = build(:weekly_plan, status: nil)
      expect(plan).not_to be_valid
    end

    it "requires week_number > 0 when present" do
      plan = build(:weekly_plan, week_number: 0)
      expect(plan).not_to be_valid
    end

    it "allows nil week_number" do
      plan = build(:weekly_plan, week_number: nil)
      expect(plan).to be_valid
    end
  end

  describe "enums" do
    it "supports draft, active, and completed statuses" do
      expect(WeeklyPlan.statuses.keys).to contain_exactly("draft", "active", "completed")
    end
  end

  describe "scopes" do
    it ".current returns active plans" do
      active = create(:weekly_plan, status: :active)
      draft = create(:weekly_plan, status: :draft)
      expect(WeeklyPlan.current).to include(active)
      expect(WeeklyPlan.current).not_to include(draft)
    end
  end
end
