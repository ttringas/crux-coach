require "rails_helper"

RSpec.describe "Authentication redirects", type: :request do
  it "redirects to calendar after sign in for onboarded users" do
    user = create(:user, password: "password123!")
    create(:climber_profile, user: user, onboarding_completed: true)

    user.update!(magic_link_code: "123456", magic_link_sent_at: Time.current)
    post verify_magic_link_code_path, params: { email: user.email, code: "123456" }

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

  it "redirects non-onboarded users to onboarding" do
    user = create(:user)
    create(:climber_profile, user: user, onboarding_completed: false)
    sign_in user

    get training_blocks_path

    expect(response).to redirect_to(onboarding_path(1))
  end

  it "redirects unauthenticated users to sign in" do
    get calendar_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
