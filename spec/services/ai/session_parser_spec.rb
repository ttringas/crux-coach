require "rails_helper"

RSpec.describe Ai::SessionParser do
  let(:user) { create(:user) }
  let(:climber_profile) { create(:climber_profile, user: user) }

  describe ".call" do
    it "parses raw text into structured session data" do
      parsed_json = {
        "session_type" => "climbing",
        "duration_minutes" => 90,
        "perceived_exertion" => 7,
        "climbs_logged" => [
          { "grade" => "V5", "style" => "boulder", "attempts" => 3, "sent" => true }
        ],
        "exercises_logged" => []
      }

      mock_response = OpenStruct.new(content: JSON.generate(parsed_json))
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      result = described_class.call(
        raw_text: "Climbed for 90 minutes, sent a V5 in 3 tries",
        climber_profile: climber_profile
      )

      expect(result).to eq(parsed_json)
      expect(result["session_type"]).to eq("climbing")
      expect(result["duration_minutes"]).to eq(90)
      expect(result["climbs_logged"].length).to eq(1)

      expect(Ai::Client).to have_received(:generate).with(
        prompt: anything,
        system: anything,
        user: user,
        interaction_type: :session_parsing,
        max_tokens: 1000
      )
    end

    it "extracts JSON embedded in surrounding text" do
      json_with_wrapper = "Here is the parsed data:\n{\"session_type\": \"hangboard\", \"duration_minutes\": 45}\nDone."
      mock_response = OpenStruct.new(content: json_with_wrapper)
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      result = described_class.call(
        raw_text: "Did hangboard for 45 min",
        climber_profile: climber_profile
      )

      expect(result["session_type"]).to eq("hangboard")
      expect(result["duration_minutes"]).to eq(45)
    end

    it "raises an error when the response is not valid JSON" do
      mock_response = OpenStruct.new(content: "This is not JSON at all")
      allow(Ai::Client).to receive(:generate).and_return(mock_response)

      expect {
        described_class.call(
          raw_text: "Some session text",
          climber_profile: climber_profile
        )
      }.to raise_error(Ai::Client::Error, /not valid JSON/)
    end

    it "propagates Ai::Client::Error from the client" do
      allow(Ai::Client).to receive(:generate)
        .and_raise(Ai::Client::Error.new("API failure"))

      expect {
        described_class.call(
          raw_text: "Some session text",
          climber_profile: climber_profile
        )
      }.to raise_error(Ai::Client::Error, /API failure/)
    end
  end
end
