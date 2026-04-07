require "rails_helper"

RSpec.describe Ai::TrainingBlockGenerator do
  describe ".validate_parsed_response!" do
    # Access the private method for testing
    def validate(parsed)
      described_class.send(:validate_parsed_response!, parsed)
    end

    it "accepts a valid response" do
      parsed = {
        "name" => "Power Block",
        "focus" => "power",
        "weeks" => [
          {
            "sessions" => [
              { "session_type" => "climbing", "day_of_week" => 0, "title" => "Bouldering" }
            ]
          }
        ]
      }

      expect { validate(parsed) }.not_to raise_error
    end

    it "rejects response missing name" do
      parsed = {
        "weeks" => [{ "sessions" => [{ "session_type" => "climbing" }] }]
      }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /missing 'name'/)
    end

    it "rejects response with nil weeks" do
      parsed = { "name" => "Block", "weeks" => nil }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /missing 'weeks'/)
    end

    it "rejects response with non-array weeks" do
      parsed = { "name" => "Block", "weeks" => "not an array" }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /must be an array/)
    end

    it "rejects response with empty weeks" do
      parsed = { "name" => "Block", "weeks" => [] }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /is empty/)
    end

    it "rejects week with nil sessions" do
      parsed = {
        "name" => "Block",
        "weeks" => [{ "sessions" => nil }]
      }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /Week 1 missing 'sessions'/)
    end

    it "rejects week with non-array sessions" do
      parsed = {
        "name" => "Block",
        "weeks" => [{ "sessions" => "invalid" }]
      }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /must be an array/)
    end

    it "rejects session missing session_type" do
      parsed = {
        "name" => "Block",
        "weeks" => [
          { "sessions" => [{ "day_of_week" => 0, "title" => "Session" }] }
        ]
      }

      expect { validate(parsed) }.to raise_error(Ai::Client::Error, /missing 'session_type'/)
    end
  end

  describe ".create_training_block!" do
    let(:profile) { create(:climber_profile) }
    let(:start_date) { Date.current.beginning_of_week(:monday) }
    let(:end_date) { start_date + 2.weeks }

    let(:valid_parsed) do
      {
        "name" => "Test Block",
        "focus" => "power",
        "ai_reasoning" => "Test reasoning",
        "overall_focus" => "Test focus",
        "weeks" => [
          {
            "summary" => "Week 1",
            "week_focus" => "Power",
            "sessions" => [
              {
                "day_of_week" => 0,
                "session_type" => "climbing",
                "title" => "Bouldering",
                "description" => "Hard bouldering",
                "estimated_duration_minutes" => 90,
                "intensity" => "high",
                "exercises" => []
              }
            ]
          }
        ]
      }
    end

    it "deactivates current blocks inside the transaction" do
      existing_block = create(:training_block, climber_profile: profile, status: :active)

      # Force a failure after deactivation but during block creation
      allow(profile.training_blocks).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

      expect {
        described_class.send(:create_training_block!, profile, valid_parsed, start_date, end_date, 2)
      }.to raise_error(ActiveRecord::RecordInvalid)

      # The existing block should NOT be deactivated because the transaction rolled back
      expect(existing_block.reload).to be_active
    end
  end
end
