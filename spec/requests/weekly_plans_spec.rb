require "rails_helper"

RSpec.describe "WeeklyPlans", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }
  let!(:training_block) { create(:training_block, climber_profile: profile) }

  before { sign_in user }

  describe "GET /plan" do
    it "returns 200" do
      get weekly_plans_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /plan/:id" do
    it "returns 200" do
      plan = create(:weekly_plan, training_block: training_block, climber_profile: profile)
      get weekly_plan_path(plan)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /plan" do
    it "redirects to the generated week on success" do
      weekly_plan = create(:weekly_plan, climber_profile: profile, training_block: training_block, week_of: Date.current.beginning_of_week(:monday))
      allow(Ai::PlanGenerator).to receive(:call).and_return(weekly_plan)

      post weekly_plans_path, params: { training_days: [ "1" ], activities: [ "hangboarding" ] }

      expect(Ai::PlanGenerator).to have_received(:call)
      expect(response).to redirect_to(weekly_plans_path(week_of: weekly_plan.week_of))
      expect(flash[:notice]).to eq("Next week plan generated.")
    end

    it "redirects with an alert when generation fails" do
      allow(Ai::PlanGenerator).to receive(:call).and_raise(Ai::Client::Error.new("Plan failed"))

      post weekly_plans_path

      expect(response).to redirect_to(weekly_plans_path)
      expect(flash[:alert]).to eq("Plan failed")
    end
  end
end
