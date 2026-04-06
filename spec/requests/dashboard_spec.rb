require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  describe "GET /dashboard" do
    context "when authenticated" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "returns 200" do
        get dashboard_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        get dashboard_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
