require "rails_helper"

RSpec.describe Ai::SessionCalibrator do
  describe ".validate_parsed_response!" do
    def validate(parsed)
      described_class.send(:validate_parsed_response!, parsed)
    end

    it "accepts a valid response" do
      parsed = {
        "exercises" => [ { "name" => "Hangboard repeaters" } ],
        "reasoning" => "Light day given soreness"
      }
      expect { validate(parsed) }.not_to raise_error
    end

    it "rejects non-hash" do
      expect { validate([]) }.to raise_error(Ai::Client::Error, /not a JSON object/)
    end

    it "rejects missing exercises array" do
      expect { validate({ "reasoning" => "x" }) }.to raise_error(Ai::Client::Error, /missing 'exercises'/)
    end

    it "rejects empty exercises" do
      expect { validate({ "exercises" => [] }) }.to raise_error(Ai::Client::Error, /no exercises/)
    end

    it "rejects exercise without name" do
      expect { validate({ "exercises" => [ { "sets" => 3 } ] }) }.to raise_error(Ai::Client::Error, /missing name/)
    end
  end

  describe ".normalize_exercises" do
    it "drops blank-name entries and assigns ids and defaults" do
      raw = [
        { "name" => "  Pull-ups  ", "sets" => 3, "target_reps" => 8 },
        { "name" => "" },
        { "name" => "Repeaters", "rep_unit" => "seconds", "duration" => "7s" }
      ]

      normalized = described_class.normalize_exercises(raw)
      expect(normalized.size).to eq(2)
      expect(normalized.first["name"]).to eq("Pull-ups")
      expect(normalized.first["rep_unit"]).to eq("reps")
      expect(normalized.first["source"]).to eq("calibration")
      expect(normalized.first["id"]).to be_present
      expect(normalized.last["rep_unit"]).to eq("seconds")
    end
  end

  describe ".call" do
    let(:user) { create(:user) }
    let(:profile) { create(:climber_profile, user: user) }
    let(:block) { create(:training_block, climber_profile: profile) }
    let(:weekly_plan) { create(:weekly_plan, training_block: block, climber_profile: profile) }
    let(:planned_session) do
      create(:planned_session,
        weekly_plan: weekly_plan,
        finger_soreness: 4,
        energy_level: 2,
        exercises: [ { "name" => "Limit Bouldering", "sets" => 5 } ])
    end

    it "calls Ai::Client and returns parsed result" do
      response = OpenStruct.new(content: {
        "exercises" => [ { "name" => "Skill Bouldering", "sets" => 3, "target_reps" => 5, "target_grade" => "V2" } ],
        "reasoning" => "Your fingers are sore — swapping limit bouldering for technique-focused volume."
      }.to_json)

      expect(Ai::Client).to receive(:generate).with(
        hash_including(
          interaction_type: :session_calibration,
          user: user
        )
      ).and_return(response)

      result = described_class.call(planned_session: planned_session, feedback: "Fingers a bit cooked")
      expect(result[:exercises].first["name"]).to eq("Skill Bouldering")
      expect(result[:reasoning]).to include("technique-focused")
    end
  end
end
