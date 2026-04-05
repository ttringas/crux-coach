require "rails_helper"

RSpec.describe "SessionLogs", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "POST /log" do
    it "creates a session log from parsed payload and ignores overridden fields" do
      parsed = {
        "session_type" => "weird",
        "duration_minutes" => 90,
        "perceived_exertion" => 7,
        "climbs_logged" => [ { "grade" => "V5" } ],
        "exercises_logged" => [ { "name" => "Hangboard" } ]
      }

      expect(Ai::SessionParser).not_to receive(:call)

      post session_logs_path, params: {
        session_log: {
          raw_input: "Did a session",
          structured_data: parsed.to_json,
          session_type: "strength",
          duration_minutes: 10,
          perceived_exertion: 2,
          date: Date.current.to_s,
          notes: "Felt good"
        }
      }

      expect(response).to redirect_to(session_log_path(SessionLog.last))

      log = SessionLog.last
      expect(log.session_type).to eq("climbing")
      expect(log.duration_minutes).to eq(90)
      expect(log.perceived_exertion).to eq(7)
      expect(log.climbs_logged.first["grade"]).to eq("V5")
      expect(log.exercises_logged.first["name"]).to eq("Hangboard")
      expect(log.notes).to eq("Felt good")
    end

    it "creates a session log from structured inputs when raw input is blank" do
      expect(Ai::SessionParser).not_to receive(:call)

      post session_logs_path, params: {
        session_log: {
          raw_input: "  ",
          session_type: "mobility",
          date: Date.current.to_s,
          duration_minutes: 45,
          perceived_exertion: 4
        }
      }

      expect(response).to redirect_to(session_log_path(SessionLog.last))
      log = SessionLog.last
      expect(log.session_type).to eq("mobility")
      expect(log.duration_minutes).to eq(45)
      expect(log.perceived_exertion).to eq(4)
      expect(log.raw_input).to be_blank
    end

    it "falls back to the AI parser when structured_data is invalid JSON" do
      allow(Ai::SessionParser).to receive(:call).and_return(
        {
          "session_type" => "hangboard",
          "duration_minutes" => 35,
          "perceived_exertion" => 6
        }
      )

      post session_logs_path, params: {
        session_log: {
          raw_input: "Hangboard session",
          structured_data: "{not json",
          date: Date.current.to_s
        }
      }

      expect(Ai::SessionParser).to have_received(:call).with(raw_text: "Hangboard session", climber_profile: profile)
      expect(response).to redirect_to(session_log_path(SessionLog.last))
      log = SessionLog.last
      expect(log.session_type).to eq("hangboard")
      expect(log.duration_minutes).to eq(35)
      expect(log.perceived_exertion).to eq(6)
    end

    it "renders validation errors when AI parsing fails" do
      allow(Ai::SessionParser).to receive(:call).and_raise(Ai::Client::Error.new("AI down"))

      post session_logs_path, params: {
        session_log: {
          raw_input: "Did a session",
          session_type: "climbing",
          date: Date.current.to_s
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("AI down")
    end
  end

  describe "GET /log" do
    it "filters by type and date range" do
      create(:session_log, climber_profile: profile, session_type: :climbing, date: Date.current - 10.days)
      target = create(:session_log, climber_profile: profile, session_type: :hangboard, date: Date.current - 2.days)
      create(:session_log, climber_profile: profile, session_type: :hangboard, date: Date.current - 30.days)

      get session_logs_path, params: {
        session_type: "hangboard",
        date_from: (Date.current - 5.days).to_s,
        date_to: Date.current.to_s
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(target.session_type.humanize)
      expect(response.body).to include(target.date.strftime("%b %d, %Y"))
      expect(response.body).not_to include((Date.current - 30.days).strftime("%b %d, %Y"))
    end
  end

  describe "POST /log/parse" do
    it "returns a JSON error when raw input is blank" do
      post parse_session_logs_path, params: { session_log: { raw_input: "" } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Raw input is required.")
    end

    it "returns a JSON error when the AI parser raises" do
      allow(Ai::SessionParser).to receive(:call).and_raise(Ai::Client::Error.new("Parser error"))

      post parse_session_logs_path, params: { session_log: { raw_input: "Did a session" } }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Parser error")
    end
  end
end
