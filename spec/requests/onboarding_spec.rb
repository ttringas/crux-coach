require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: false) }

  before { sign_in user }

  it "redirects to plans after the final step" do
    allow(GenerateTrainingBlockJob).to receive(:perform_later)

    patch onboarding_path(6), params: { climber_profile: {} }

    expect(GenerateTrainingBlockJob).to have_received(:perform_later)
    expect(response).to redirect_to(training_blocks_path)
  end
end
