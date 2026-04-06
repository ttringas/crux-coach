require "rails_helper"

RSpec.describe SessionLog, type: :model do
  it "is valid with required attributes" do
    log = build(:session_log)
    expect(log).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:climber_profile) }
    it { is_expected.to belong_to(:planned_session).optional }
  end

  describe "validations" do
    it "requires a date" do
      log = build(:session_log, date: nil)
      expect(log).not_to be_valid
      expect(log.errors[:date]).to be_present
    end

    it "requires session_type" do
      log = build(:session_log, session_type: nil)
      expect(log).not_to be_valid
    end

    it "requires duration_minutes > 0 when present" do
      log = build(:session_log, duration_minutes: 0)
      expect(log).not_to be_valid
    end

    it "allows nil duration_minutes" do
      log = build(:session_log, duration_minutes: nil)
      expect(log).to be_valid
    end

    it "requires perceived_exertion in 1..10 when present" do
      log = build(:session_log, perceived_exertion: 11)
      expect(log).not_to be_valid
    end

    it "requires energy_level in 1..5 when present" do
      log = build(:session_log, energy_level: 6)
      expect(log).not_to be_valid
    end

    it "requires finger_soreness in 1..5 when present" do
      log = build(:session_log, finger_soreness: 0)
      expect(log).not_to be_valid
    end

    it "allows nil for all rating fields" do
      log = build(:session_log,
        perceived_exertion: nil, energy_level: nil, skin_condition: nil,
        finger_soreness: nil, general_soreness: nil, mood: nil
      )
      expect(log).to be_valid
    end
  end

  describe "enums" do
    it "supports expected session types" do
      expect(SessionLog.session_types.keys).to include("climbing", "strength", "cardio")
    end
  end

  describe "scopes" do
    it ".recent orders by date descending" do
      old = create(:session_log, date: 1.week.ago)
      recent = create(:session_log, date: Date.current)
      expect(SessionLog.recent.first).to eq(recent)
    end
  end
end
