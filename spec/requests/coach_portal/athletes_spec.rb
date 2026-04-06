require "rails_helper"

RSpec.describe "CoachPortal::Athletes", type: :request do
  let(:coach_user) { create(:user, role: :coach) }
  let!(:coach_profile) { create(:climber_profile, user: coach_user, onboarding_completed: true) }
  let!(:coach) { create(:coach, user: coach_user) }

  let(:athlete_user) { create(:user) }
  let!(:athlete_profile) { create(:climber_profile, user: athlete_user, onboarding_completed: true) }
  let!(:coach_assignment) { create(:coach_assignment, coach: coach, climber_profile: athlete_profile) }

  describe "GET /coach_portal/athletes/:id" do
    context "when user is a coach" do
      before { sign_in coach_user }

      it "returns a successful response" do
        get coach_portal_athlete_path(athlete_profile)

        expect(response).to have_http_status(:ok)
      end
    end

    context "when user is not a coach" do
      let(:user) { create(:user) }
      let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

      before { sign_in user }

      it "redirects to the calendar page" do
        get coach_portal_athlete_path(athlete_profile)

        expect(response).to redirect_to(calendar_path)
      end
    end
  end

  describe "PATCH /coach_portal/athletes/:id" do
    context "when user is a coach" do
      let!(:training_block) { create(:training_block, climber_profile: athlete_profile) }
      let!(:weekly_plan) { create(:weekly_plan, training_block: training_block, climber_profile: athlete_profile, status: :active) }

      before { sign_in coach_user }

      it "updates the athlete plan and redirects" do
        patch coach_portal_athlete_path(athlete_profile), params: {
          weekly_plan: { coach_notes: "Updated coach notes" }
        }

        expect(response).to redirect_to(coach_portal_athlete_path(athlete_profile))
        expect(weekly_plan.reload.coach_notes).to eq("Updated coach notes")
      end
    end
  end
end
