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

  describe "POST /calibrate" do
    before { ActiveJob::Base.queue_adapter = :test }

    it "enqueues the calibration job and marks status in_progress" do
      expect {
        post calibrate_weekly_plan_planned_session_path(weekly_plan, planned_session),
          params: { feedback: "Right elbow is sore" },
          headers: { "Accept" => "application/json" },
          as: :json
      }.to have_enqueued_job(CalibrateSessionJob)
        .with(planned_session_id: planned_session.id, feedback: "Right elbow is sore")

      planned_session.reload
      expect(planned_session.calibration_status).to eq("in_progress")
      expect(planned_session.calibration_feedback).to eq("Right elbow is sore")
    end

    it "rejects double-submit while a calibration is already in progress" do
      planned_session.update!(calibration_status: "in_progress", calibration_requested_at: Time.current)

      expect {
        post calibrate_weekly_plan_planned_session_path(weekly_plan, planned_session),
          params: { feedback: "again" }, as: :json
      }.not_to have_enqueued_job(CalibrateSessionJob)
    end

    it "marks a stale in_progress as failed and re-enqueues" do
      planned_session.update!(calibration_status: "in_progress", calibration_requested_at: 10.minutes.ago)

      expect {
        post calibrate_weekly_plan_planned_session_path(weekly_plan, planned_session),
          params: { feedback: "fresh" }, as: :json
      }.to have_enqueued_job(CalibrateSessionJob)
    end

    it "blocks at the daily calibration limit with a friendly message" do
      Ai::UsageGuard::SESSION_CALIBRATION_LIMIT_PER_DAY.times do
        create(:ai_interaction, user: user, interaction_type: :session_calibration, created_at: 1.hour.ago)
      end

      expect {
        post calibrate_weekly_plan_planned_session_path(weekly_plan, planned_session),
          params: { feedback: "another one" }, as: :json
      }.not_to have_enqueued_job(CalibrateSessionJob)

      expect(response).to have_http_status(:too_many_requests)
      planned_session.reload
      expect(planned_session.calibration_status).to eq("failed")
      expect(planned_session.calibration_error).to include("calibration limit of 5")
    end
  end

  describe "GET /show with stale in_progress calibration" do
    it "auto-marks stale calibrations as failed before rendering" do
      planned_session.update!(calibration_status: "in_progress", calibration_requested_at: 10.minutes.ago)

      get weekly_plan_planned_session_path(weekly_plan, planned_session)

      expect(response).to have_http_status(:ok)
      planned_session.reload
      expect(planned_session.calibration_status).to eq("failed")
      expect(planned_session.calibration_error).to match(/timed out/)
    end
  end

  describe "POST /revert_calibration" do
    it "restores previous exercises and clears calibration state" do
      planned_session.update!(
        previous_exercises: [ { "name" => "Original" } ],
        exercises: [ { "name" => "Calibrated" } ],
        calibration_status: "completed",
        calibration_reasoning: "did stuff"
      )

      post revert_calibration_weekly_plan_planned_session_path(weekly_plan, planned_session), as: :json

      planned_session.reload
      expect(planned_session.exercises).to eq([ { "name" => "Original" } ])
      expect(planned_session.previous_exercises).to be_nil
      expect(planned_session.calibration_status).to be_nil
      expect(planned_session.calibration_reasoning).to be_nil
    end

    it "is a no-op if nothing to revert" do
      post revert_calibration_weekly_plan_planned_session_path(weekly_plan, planned_session), as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /calibration_status" do
    it "returns idle when no calibration has run" do
      get calibration_status_weekly_plan_planned_session_path(weekly_plan, planned_session), as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("idle")
      expect(json["can_revert"]).to eq(false)
    end

    it "returns in_progress when calibration is running" do
      planned_session.update!(calibration_status: "in_progress", calibration_requested_at: Time.current)

      get calibration_status_weekly_plan_planned_session_path(weekly_plan, planned_session), as: :json
      expect(JSON.parse(response.body)["status"]).to eq("in_progress")
    end
  end

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
