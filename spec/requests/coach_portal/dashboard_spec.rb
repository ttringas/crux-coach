require "rails_helper"

RSpec.describe "CoachPortal::Dashboard", type: :request do
  describe "GET /coach_portal/dashboard" do
    context "when user is a coach" do
      let(:coach_user) { create(:user, role: :coach) }
      let!(:coach_profile) { create(:climber_profile, user: coach_user, onboarding_completed: true) }
      let!(:coach) { create(:coach, user: coach_user) }

      before { sign_in coach_user }

      it "returns a successful response" do
        get coach_portal_dashboard_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not a coach" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "redirects to the calendar page" do
        get coach_portal_dashboard_path

        expect(response).to redirect_to(calendar_path)
      end
    end

    context "when user is not authenticated" do
      it "redirects to the sign in page" do
        get coach_portal_dashboard_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
