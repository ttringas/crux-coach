require "rails_helper"

RSpec.describe "WeeklyPlans", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }
  let!(:block) { create(:training_block, climber_profile: profile) }

  before { sign_in user }

  describe "GET /plan" do
    it "returns 200" do
      get weekly_plans_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /plan/:id" do
    it "returns 200" do
      plan = create(:weekly_plan, training_block: block, climber_profile: profile)
      get weekly_plan_path(plan)
      expect(response).to have_http_status(:ok)
    end
  end
end
