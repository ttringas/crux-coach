require "rails_helper"

RSpec.describe Ai::PlanGenerator, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  def stub_ai_response(payload)
    allow(Ai::Client).to receive(:generate).and_return(OpenStruct.new(content: payload.to_json))
  end

  it "creates a weekly plan with normalized sessions" do
    travel_to Date.new(2026, 4, 6) do
      training_block = create(:training_block, climber_profile: profile)
      payload = {
        "summary" => "Week summary",
        "sessions" => [
          {
            "day_of_week" => 8,
            "session_type" => "Unknown",
            "title" => "Session A",
            "description" => "Desc",
            "estimated_duration_minutes" => 45,
            "intensity" => "max",
            "exercises" => [ { "name" => "X" } ]
          },
          {
            "day_of_week" => -1,
            "session_type" => "board",
            "title" => "Session B",
            "description" => "Desc",
            "estimated_duration_minutes" => 30,
            "intensity" => "low",
            "exercises" => []
          }
        ]
      }
      stub_ai_response(payload)

      weekly_plan = described_class.call(climber_profile: profile)

      expect(weekly_plan.training_block).to eq(training_block)
      expect(weekly_plan.status).to eq("draft")
      expect(weekly_plan.week_of).to eq(Date.current.beginning_of_week(:monday))
      expect(weekly_plan.summary).to eq("Week summary")

      sessions = weekly_plan.planned_sessions.order(:title)
      expect(sessions.map(&:day_of_week)).to eq([ 6, 0 ])
      expect(sessions.map(&:session_type)).to eq([ "climbing", "board" ])
      expect(sessions.map(&:intensity)).to eq([ "max_effort", "low" ])
    end
  end

  it "filters sessions based on training days and activities" do
    travel_to Date.new(2026, 4, 6) do
      create(:training_block, climber_profile: profile)
      payload = {
        "summary" => "Filtered week",
        "sessions" => [
          { "day_of_week" => 1, "session_type" => "hangboard", "title" => "HB", "description" => "", "intensity" => "low" },
          { "day_of_week" => 0, "session_type" => "hangboard", "title" => "Wrong day", "description" => "", "intensity" => "low" },
          { "day_of_week" => 1, "session_type" => "strength", "title" => "Wrong type", "description" => "", "intensity" => "low" },
          { "day_of_week" => 1, "session_type" => "rest", "title" => "Rest", "description" => "", "intensity" => "low" }
        ]
      }
      stub_ai_response(payload)

      weekly_plan = described_class.call(
        climber_profile: profile,
        training_days: [ "1" ],
        activities: [ "hangboarding" ]
      )

      sessions = weekly_plan.planned_sessions.order(:title)
      expect(sessions.map(&:title)).to eq([ "HB", "Rest" ])
      expect(sessions.map(&:day_of_week)).to eq([ 1, 1 ])
      expect(sessions.map(&:session_type)).to eq([ "hangboard", "rest" ])
    end
  end

  it "extracts JSON when the AI response includes extra text" do
    travel_to Date.new(2026, 4, 6) do
      create(:training_block, climber_profile: profile)
      response_text = "Sure! {\"summary\":\"OK\",\"sessions\":[]}\nThanks."
      allow(Ai::Client).to receive(:generate).and_return(OpenStruct.new(content: response_text))

      weekly_plan = described_class.call(climber_profile: profile)

      expect(weekly_plan.summary).to eq("OK")
      expect(weekly_plan.planned_sessions).to be_empty
    end
  end

  it "raises an error when no training block exists" do
    payload = { "summary" => "Week summary", "sessions" => [] }
    stub_ai_response(payload)

    expect {
      described_class.call(climber_profile: profile)
    }.to raise_error(Ai::Client::Error, "No training block available for plan generation")
  end

  it "raises a client error for invalid JSON responses" do
    create(:training_block, climber_profile: profile)
    allow(Ai::Client).to receive(:generate).and_return(OpenStruct.new(content: "not json"))

    expect {
      described_class.call(climber_profile: profile)
    }.to raise_error(Ai::Client::Error, "AI response was not valid JSON")
  end
end
