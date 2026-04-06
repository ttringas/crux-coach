require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  describe "when authenticated" do
    before { sign_in user }

    describe "GET /profile" do
      it "returns 200" do
        get profile_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /profile/edit" do
      it "returns 200" do
        get edit_profile_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /profile" do
      it "updates profile and redirects" do
        patch profile_path, params: {
          user: { name: "New Name" },
          climber_profile: { height_inches: 70, weight_lbs: 160 }
        }
        expect(response).to redirect_to(profile_path)
        expect(user.reload.name).to eq("New Name")
        expect(profile.reload.height_inches).to eq(70)
      end
    end
  end

  describe "when unauthenticated" do
    it "redirects to sign in" do
      get profile_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
