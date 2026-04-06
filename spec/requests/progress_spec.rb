require "rails_helper"

RSpec.describe "Progress", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "GET /progress" do
    it "returns 200" do
      get progress_path
      expect(response).to have_http_status(:ok)
    end
  end
end
