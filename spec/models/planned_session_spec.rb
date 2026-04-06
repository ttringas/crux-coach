require "rails_helper"

RSpec.describe PlannedSession, type: :model do
  it "is valid with required attributes" do
    session = build(:planned_session)
    expect(session).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:weekly_plan) }
    it { is_expected.to have_one(:session_log).dependent(:nullify) }
  end

  describe "validations" do
    it "requires day_of_week in 0..6" do
      session = build(:planned_session, day_of_week: 7)
      expect(session).not_to be_valid
    end

    it "requires a title" do
      session = build(:planned_session, title: nil)
      expect(session).not_to be_valid
      expect(session.errors[:title]).to be_present
    end

    it "requires session_type" do
      session = build(:planned_session, session_type: nil)
      expect(session).not_to be_valid
    end

    it "requires intensity" do
      session = build(:planned_session, intensity: nil)
      expect(session).not_to be_valid
    end

    it "requires position >= 0" do
      session = build(:planned_session, position: -1)
      expect(session).not_to be_valid
    end

    it "requires estimated_duration_minutes >= 0 when present" do
      session = build(:planned_session, estimated_duration_minutes: -1)
      expect(session).not_to be_valid
    end

    it "allows nil estimated_duration_minutes" do
      session = build(:planned_session, estimated_duration_minutes: nil)
      expect(session).to be_valid
    end
  end

  describe "enums" do
    it "supports expected session types" do
      expect(PlannedSession.session_types.keys).to include(
        "climbing", "board", "hangboard", "strength", "cardio", "mobility", "rest"
      )
    end

    it "supports expected intensity levels" do
      expect(PlannedSession.intensities.keys).to contain_exactly("low", "moderate", "high", "max_effort")
    end

    it "supports expected statuses" do
      expect(PlannedSession.statuses.keys).to contain_exactly("todo", "in_progress", "completed", "skipped")
    end
  end

  describe "#exercises_logged_payload" do
    it "returns empty array when exercises are blank" do
      session = build(:planned_session, exercises: [])
      expect(session.exercises_logged_payload).to eq([])
    end

    it "returns exercise data when logs have content" do
      session = build(:planned_session,
        exercises: [ { "name" => "Pull-ups", "sets" => 3, "reps" => 10 } ],
        exercise_logs: [ { "exercise_index" => 0, "completed" => true, "actual_sets" => "3", "actual_reps" => "8" } ]
      )
      payload = session.exercises_logged_payload
      expect(payload.length).to eq(1)
      expect(payload.first[:name]).to eq("Pull-ups")
      expect(payload.first[:sets]).to eq("3")
      expect(payload.first[:reps]).to eq("8")
    end

    it "skips exercises with no logged data" do
      session = build(:planned_session,
        exercises: [ { "name" => "Pull-ups" }, { "name" => "Hangs" } ],
        exercise_logs: [ { "exercise_index" => 0, "completed" => true } ]
      )
      payload = session.exercises_logged_payload
      expect(payload.length).to eq(1)
    end
  end
end
