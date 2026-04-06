require "rails_helper"

RSpec.describe "Admin::AiUsage", type: :request do
  describe "GET /admin/ai_usage" do
    context "when user is an admin" do
      let(:user) { create(:user, role: :admin) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "returns a successful response" do
        get admin_ai_usage_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not an admin" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "redirects to the calendar page" do
        get admin_ai_usage_path

        expect(response).to redirect_to(calendar_path)
      end
    end

    context "when user is not authenticated" do
      it "redirects to the sign in page" do
        get admin_ai_usage_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
