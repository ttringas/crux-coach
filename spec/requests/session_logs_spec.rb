require "rails_helper"

RSpec.describe "SessionLogs", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "GET /log" do
    it "returns 200" do
      get session_logs_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /log/new" do
    it "returns 200" do
      get new_session_log_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /log" do
    it "creates a session log and redirects" do
      expect {
        post session_logs_path, params: {
          session_log: {
            session_type: "climbing",
            date: Date.current.to_s,
            duration_minutes: 60,
            perceived_exertion: 5,
            energy_level: 3,
            notes: "Good session"
          }
        }
      }.to change(SessionLog, :count).by(1)

      expect(response).to redirect_to(session_log_path(SessionLog.last))
    end
  end

  describe "GET /log/:id" do
    it "returns 200" do
      session_log = create(:session_log, climber_profile: profile)
      get session_log_path(session_log)
      expect(response).to have_http_status(:ok)
    end
  end
end
