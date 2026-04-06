require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    context "when unauthenticated" do
      it "returns 200" do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "redirects to authenticated root" do
        get root_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
