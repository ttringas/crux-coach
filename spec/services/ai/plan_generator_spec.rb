require "rails_helper"

RSpec.describe Ai::PlanGenerator do
  let(:user) { create(:user) }
  let(:climber_profile) { create(:climber_profile, user: user) }
  let!(:training_block) do
    create(:training_block, climber_profile: climber_profile, status: :active,
           started_at: Date.current.beginning_of_week(:monday),
           ends_at: Date.current.beginning_of_week(:monday) + 4.weeks)
  end

  let(:ai_plan_response) do
    {
      "summary" => "A balanced week of climbing and strength",
      "sessions" => [
        {
          "day_of_week" => 0,
          "session_type" => "climbing",
          "title" => "Boulder Session",
          "description" => "Focus on power moves",
          "estimated_duration_minutes" => 90,
          "intensity" => "high",
          "exercises" => [{ "name" => "Campus Board", "sets" => 3, "reps" => "5" }]
        },
        {
          "day_of_week" => 2,
          "session_type" => "strength",
          "title" => "Upper Body Strength",
          "description" => "Pull-ups and core",
          "estimated_duration_minutes" => 60,
          "intensity" => "moderate",
          "exercises" => []
        },
        {
          "day_of_week" => 5,
          "session_type" => "rest",
          "title" => "Rest Day",
          "description" => "Active recovery",
          "estimated_duration_minutes" => 0,
          "intensity" => "low",
          "exercises" => []
        }
      ]
    }
  end

  before do
    mock_response = OpenStruct.new(content: JSON.generate(ai_plan_response))
    allow(Ai::Client).to receive(:generate).and_return(mock_response)
  end

  describe ".call" do
    it "creates a WeeklyPlan with PlannedSessions" do
      result = described_class.call(climber_profile: climber_profile)

      expect(result).to be_a(WeeklyPlan)
      expect(result).to be_persisted
      expect(result.training_block).to eq(training_block)
      expect(result.status).to eq("draft")
      expect(result.summary).to eq("A balanced week of climbing and strength")
      expect(result.planned_sessions.count).to eq(3)
    end

    it "creates planned sessions with correct attributes" do
      result = described_class.call(climber_profile: climber_profile)

      boulder_session = result.planned_sessions.find_by(title: "Boulder Session")
      expect(boulder_session.day_of_week).to eq(0)
      expect(boulder_session.session_type).to eq("climbing")
      expect(boulder_session.intensity).to eq("high")
      expect(boulder_session.estimated_duration_minutes).to eq(90)
    end

    it "normalizes unknown session types to climbing" do
      ai_plan_response["sessions"][0]["session_type"] = "bouldering_fun"
      mock_response = OpenStruct.new(content: JSON.generate(ai_plan_response))
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      result = described_class.call(climber_profile: climber_profile)
      session = result.planned_sessions.find_by(title: "Boulder Session")
      expect(session.session_type).to eq("climbing")
    end

    it "normalizes unknown intensities to moderate" do
      ai_plan_response["sessions"][0]["intensity"] = "extreme"
      mock_response = OpenStruct.new(content: JSON.generate(ai_plan_response))
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      result = described_class.call(climber_profile: climber_profile)
      session = result.planned_sessions.find_by(title: "Boulder Session")
      expect(session.intensity).to eq("moderate")
    end

    it "normalizes 'max' intensity to 'max_effort'" do
      ai_plan_response["sessions"][0]["intensity"] = "max"
      mock_response = OpenStruct.new(content: JSON.generate(ai_plan_response))
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      result = described_class.call(climber_profile: climber_profile)
      session = result.planned_sessions.find_by(title: "Boulder Session")
      expect(session.intensity).to eq("max_effort")
    end

    it "clamps day_of_week to 0..6" do
      ai_plan_response["sessions"][0]["day_of_week"] = 10
      mock_response = OpenStruct.new(content: JSON.generate(ai_plan_response))
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      result = described_class.call(climber_profile: climber_profile)
      session = result.planned_sessions.find_by(title: "Boulder Session")
      expect(session.day_of_week).to eq(6)
    end

    it "calls Ai::Client.generate with correct parameters" do
      described_class.call(climber_profile: climber_profile)

      expect(Ai::Client).to have_received(:generate).with(
        prompt: anything,
        system: anything,
        user: user,
        interaction_type: :plan_generation,
        max_tokens: 16384
      )
    end

    it "raises error when no training block exists" do
      training_block.destroy!

      expect {
        described_class.call(climber_profile: climber_profile)
      }.to raise_error(Ai::Client::Error, /No training block available/)
    end

    it "raises error when AI returns invalid JSON" do
      mock_response = OpenStruct.new(content: "not json at all")
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      expect {
        described_class.call(climber_profile: climber_profile)
      }.to raise_error(Ai::Client::Error, /not valid JSON/)
    end

    it "propagates Ai::Client errors" do
      allow(Ai::Client).to receive(:generate)
        .and_raise(Ai::Client::Error.new("Provider down"))

      expect {
        described_class.call(climber_profile: climber_profile)
      }.to raise_error(Ai::Client::Error, /Provider down/)
    end

    it "stores the full AI response as ai_generated_plan" do
      result = described_class.call(climber_profile: climber_profile)
      expect(result.ai_generated_plan).to eq(ai_plan_response)
    end
  end
end
