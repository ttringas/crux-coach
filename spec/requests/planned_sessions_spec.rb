require "rails_helper"

RSpec.describe "PlannedSessions", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }
  let!(:training_block) { create(:training_block, climber_profile: profile) }
  let!(:weekly_plan) { create(:weekly_plan, training_block: training_block, climber_profile: profile) }
  let!(:planned_session) do
    create(:planned_session,
      weekly_plan: weekly_plan,
      exercises: [ { "name" => "Pull-ups", "sets" => 3, "reps" => 5 } ])
  end

  before { sign_in user }

  it "renders the queueSave action for exercise logs" do
    get weekly_plan_planned_session_path(weekly_plan, planned_session)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("change->exercise-log#queueSave")
    expect(response.body).not_to include("change->exercise-log#saveSet")
  end

  it "updates exercises via update_exercises" do
    patch update_exercises_weekly_plan_planned_session_path(weekly_plan, planned_session),
      params: {
        exercises: [
          { name: "Push-ups", sets: "4", reps: "8" },
          { name: "Rest" }
        ]
      },
      as: :json

    expect(response).to have_http_status(:ok)
    planned_session.reload
    expect(planned_session.exercises.map { |ex| ex["name"] }).to eq([ "Push-ups", "Rest" ])
    expect(planned_session.exercises.first["id"]).to be_present
  end
end
