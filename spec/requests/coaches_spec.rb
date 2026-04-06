require "rails_helper"

RSpec.describe "Coaches", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "GET /coaches" do
    it "returns 200" do
      get coaches_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /coaches/:id" do
    it "returns 200" do
      coach_user = create(:user, role: :coach)
      coach = create(:coach, user: coach_user)

      get coach_path(coach)
      expect(response).to have_http_status(:ok)
    end
  end
end
