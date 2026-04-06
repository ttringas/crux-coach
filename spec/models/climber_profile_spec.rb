require "rails_helper"

RSpec.describe ClimberProfile, type: :model do
  it "is valid with required attributes" do
    profile = build(:climber_profile)
    expect(profile).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:training_blocks).dependent(:destroy) }
    it { is_expected.to have_many(:weekly_plans).dependent(:destroy) }
    it { is_expected.to have_many(:session_logs).dependent(:destroy) }
    it { is_expected.to have_many(:climbing_benchmarks).dependent(:destroy) }
    it { is_expected.to have_many(:coach_assignments).dependent(:destroy) }
    it { is_expected.to have_many(:coaches).through(:coach_assignments) }
  end

  describe "validations" do
    it "requires numeric values >= 0 for physical attributes" do
      profile = build(:climber_profile, height_inches: -1)
      expect(profile).not_to be_valid
      expect(profile.errors[:height_inches]).to be_present
    end

    it "allows nil for optional numeric fields" do
      profile = build(:climber_profile, height_inches: nil, weight_lbs: nil)
      expect(profile).to be_valid
    end

    it "restricts weekly_training_days to max 7" do
      profile = build(:climber_profile, weekly_training_days: 8)
      expect(profile).not_to be_valid
      expect(profile.errors[:weekly_training_days]).to be_present
    end

    it "allows weekly_training_days of 7" do
      profile = build(:climber_profile, weekly_training_days: 7)
      expect(profile).to be_valid
    end
  end

  describe "scopes" do
    it ".onboarded returns profiles with completed onboarding" do
      onboarded = create(:climber_profile, onboarding_completed: true)
      not_onboarded = create(:climber_profile, onboarding_completed: false)
      expect(ClimberProfile.onboarded).to include(onboarded)
      expect(ClimberProfile.onboarded).not_to include(not_onboarded)
    end

    it ".not_onboarded returns profiles without completed onboarding" do
      not_onboarded = create(:climber_profile, onboarding_completed: false)
      expect(ClimberProfile.not_onboarded).to include(not_onboarded)
    end
  end

  describe "#available_equipment_labels" do
    it "maps equipment keys to human-readable labels" do
      profile = build(:climber_profile, available_equipment: [ "hangboard", "pull_up_bar" ])
      expect(profile.available_equipment_labels).to eq([ "Hangboard", "Pull up bar" ])
    end

    it "humanizes unknown equipment keys" do
      profile = build(:climber_profile, available_equipment: [ "unknown_thing" ])
      expect(profile.available_equipment_labels).to eq([ "Unknown thing" ])
    end
  end
end
