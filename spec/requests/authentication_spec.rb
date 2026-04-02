require "rails_helper"

RSpec.describe "Authentication redirects", type: :request do
  it "redirects to calendar after sign in for onboarded users" do
    user = create(:user, password: "password123!")
    create(:climber_profile, user: user, onboarding_completed: true)

    post user_session_path, params: { user: { email: user.email, password: "password123!" } }

    expect(response).to redirect_to(calendar_path)
  end

  it "redirects authenticated root to plans when the user has no active weekly plan" do
    user = create(:user, password: "password123!")
    create(:climber_profile, user: user, onboarding_completed: true)
    sign_in user

    get root_path

    expect(response).to redirect_to(training_blocks_path)
  end

  it "redirects authenticated root to calendar when the user has an active weekly plan" do
    user = create(:user, password: "password123!")
    profile = create(:climber_profile, user: user, onboarding_completed: true)
    block = create(:training_block, climber_profile: profile)
    create(:weekly_plan, climber_profile: profile, training_block: block, status: :active, week_of: Date.current.beginning_of_week(:monday))
    sign_in user

    get root_path

    expect(response).to redirect_to(calendar_path)
  end

  it "redirects authenticated root to calendar when the user has an active training block but no active weekly plan" do
    user = create(:user, password: "password123!")
    profile = create(:climber_profile, user: user, onboarding_completed: true)
    create(:training_block, climber_profile: profile, status: :active)
    sign_in user

    get root_path

    expect(response).to redirect_to(calendar_path)
  end
end
