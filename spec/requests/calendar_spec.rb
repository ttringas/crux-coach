require "rails_helper"

RSpec.describe "Calendar", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "GET /calendar" do
    it "returns 200 with default weekly view" do
      get calendar_path
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 with monthly view" do
      get calendar_path, params: { view: "monthly" }
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 with specific week_of param" do
      get calendar_path, params: { week_of: "2026-04-06" }
      expect(response).to have_http_status(:ok)
    end
  end
end
