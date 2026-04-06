require "rails_helper"

RSpec.describe "Admin::Plans", type: :request do
  describe "GET /admin/plans" do
    context "when user is an admin" do
      let(:user) { create(:user, role: :admin) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "returns a successful response" do
        get admin_plans_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not an admin" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "redirects to the calendar page" do
        get admin_plans_path

        expect(response).to redirect_to(calendar_path)
      end
    end
  end

  describe "GET /admin/plans/:id" do
    let(:weekly_plan) { create(:weekly_plan) }

    context "when user is an admin" do
      let(:user) { create(:user, role: :admin) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "returns a successful response" do
        get admin_plan_path(weekly_plan)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not an admin" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "redirects to the calendar page" do
        get admin_plan_path(weekly_plan)

        expect(response).to redirect_to(calendar_path)
      end
    end
  end
end
