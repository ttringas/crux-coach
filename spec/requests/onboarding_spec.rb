require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: false) }

  before { sign_in user }

  it "updates user name and sanitizes injuries" do
    patch onboarding_path(2), params: {
      user: { name: "Ava" },
      climber_profile: {
        injuries: [
          { area: "Finger", severity: "2", notes: "Sore", date_started: "2026-03-01", still_active: "1", extra: "nope" },
          { area: "", severity: "", notes: "", date_started: "", still_active: "" }
        ]
      }
    }

    expect(response).to redirect_to(onboarding_path(3))
    expect(user.reload.name).to eq("Ava")

    profile.reload
    expect(profile.injuries.size).to eq(1)
    expect(profile.injuries.first["area"]).to eq("Finger")
    expect(profile.injuries.first).not_to have_key("extra")
  end

  it "renders validation errors when the profile update is invalid" do
    patch onboarding_path(2), params: {
      climber_profile: { weekly_training_days: 9 }
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(profile.reload.weekly_training_days).to eq(3)
  end

  it "redirects to plans after the final step" do
    allow(GenerateTrainingBlockJob).to receive(:perform_later)

    patch onboarding_path(7), params: { climber_profile: {} }

    expect(GenerateTrainingBlockJob).to have_received(:perform_later)
    expect(response).to redirect_to(training_blocks_path)
  end
end
