require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: false) }

  before { sign_in user }

  it "completes onboarding and redirects to training blocks on the final step" do
    patch onboarding_path(6), params: { climber_profile: {} }

    expect(profile.reload.onboarding_completed).to be true
    expect(response).to redirect_to(training_blocks_path)
  end

  it "advances to the next step for intermediate steps" do
    patch onboarding_path(3), params: { climber_profile: { goals_short_term: "Send V6" } }

    expect(response).to redirect_to(onboarding_path(4))
  end
end
