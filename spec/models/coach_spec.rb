require "rails_helper"

RSpec.describe Coach, type: :model do
  it "is valid with required attributes" do
    coach = build(:coach)
    expect(coach).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:coach_assignments).dependent(:destroy) }
    it { is_expected.to have_many(:climber_profiles).through(:coach_assignments) }
  end

  describe "validations" do
    it "requires years_coaching >= 0 when present" do
      coach = build(:coach, years_coaching: -1)
      expect(coach).not_to be_valid
    end

    it "allows nil years_coaching" do
      coach = build(:coach, years_coaching: nil)
      expect(coach).to be_valid
    end

    it "requires rate_per_month >= 0 when present" do
      coach = build(:coach, rate_per_month: -10)
      expect(coach).not_to be_valid
    end
  end

  describe "scopes" do
    it ".accepting returns coaches accepting athletes" do
      accepting = create(:coach, accepting_athletes: true)
      not_accepting = create(:coach, accepting_athletes: false)
      expect(Coach.accepting).to include(accepting)
      expect(Coach.accepting).not_to include(not_accepting)
    end
  end
end
