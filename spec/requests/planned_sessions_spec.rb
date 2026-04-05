require "rails_helper"

RSpec.describe "PlannedSessions", type: :request do
  include ActiveSupport::Testing::TimeHelpers
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

  it "marks a session completed and creates a session log" do
    travel_to Time.zone.local(2026, 4, 10, 9, 30) do
      patch weekly_plan_planned_session_path(weekly_plan, planned_session),
        params: {
          planned_session: {
            status: "completed",
            perceived_exertion: 8,
            session_notes: "Felt solid"
          }
        },
        as: :json

      expect(response).to have_http_status(:ok)
      planned_session.reload
      expect(planned_session.status).to eq("completed")
      expect(planned_session.started_at).to be_present
      expect(planned_session.completed_at).to be_present

      log = planned_session.session_log
      expect(log).to be_present
      expect(log.session_type).to eq(planned_session.session_type)
      expect(log.date).to eq(Date.new(2026, 4, 10))
      expect(log.duration_minutes).to eq(planned_session.estimated_duration_minutes)
      expect(log.perceived_exertion).to eq(8)
      expect(log.notes).to eq("Felt solid")
    end
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

  it "filters out invalid exercises when updating" do
    patch update_exercises_weekly_plan_planned_session_path(weekly_plan, planned_session),
      params: {
        exercises: [
          { name: "" },
          { title: "Core circuit", reps: "10" },
          "bad"
        ]
      },
      as: :json

    expect(response).to have_http_status(:ok)
    planned_session.reload
    expect(planned_session.exercises.map { |ex| ex["name"] }).to eq([ "Core circuit" ])
  end
end
