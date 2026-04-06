require "rails_helper"

RSpec.describe CoachAssignment, type: :model do
  it "is valid with required attributes" do
    assignment = build(:coach_assignment)
    expect(assignment).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:coach) }
    it { is_expected.to belong_to(:climber_profile) }
  end

  describe "validations" do
    it "requires a status" do
      assignment = build(:coach_assignment, status: nil)
      expect(assignment).not_to be_valid
    end
  end

  describe "enums" do
    it "supports active, paused, and ended statuses" do
      expect(CoachAssignment.statuses.keys).to contain_exactly("active", "paused", "ended")
    end
  end

  describe "scopes" do
    it ".current returns only active assignments" do
      active = create(:coach_assignment, status: :active)
      paused = create(:coach_assignment, status: :paused)
      ended = create(:coach_assignment, status: :ended)
      expect(CoachAssignment.current).to include(active)
      expect(CoachAssignment.current).not_to include(paused, ended)
    end
  end
end
