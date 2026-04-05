require "rails_helper"

RSpec.describe "TrainingBlocks", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  it "enqueues a generation job and returns a turbo stream response" do
    allow(GenerateTrainingBlockJob).to receive(:perform_later)

    post training_blocks_path,
      params: {
        start_date: Date.current.beginning_of_week(:monday).to_s,
        end_date: (Date.current.beginning_of_week(:monday) + 4.weeks).to_s,
        comments: "Focus on endurance",
        training_days: [ "Monday" ],
        activities: [ "Bouldering" ]
      },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    expect(GenerateTrainingBlockJob).to have_received(:perform_later).with(hash_including(climber_profile_id: profile.id))
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    expect(response.body).to include("Training block generation")
    expect(response.body).to include("Coach is building your full block")
  end

  it "renders the date range helper defaults on the index page" do
    get training_blocks_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Maximum range: 12 weeks.")
    expect(response.body).to include(Date.current.to_s)
    expect(response.body).to include((Date.current + 8.weeks).to_s)
    expect(response.body).to include("Selected range: about 8 weeks.")
  end

  it "returns status payloads for polling" do
    profile.update!(
      training_block_generation_status: "completed",
      training_block_generation_training_block_id: create(:training_block, climber_profile: profile).id
    )

    get status_training_blocks_path, headers: { "ACCEPT" => "application/json" }

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body
    expect(payload["status"]).to eq("completed")
    expect(payload["notice"]).to eq("Your new training block is ready and now visible below.")
    expect(payload["html"]).to include("Plan ready")
  end

  it "returns a pending status payload while generation is running" do
    profile.update!(training_block_generation_status: "pending")

    get status_training_blocks_path, headers: { "ACCEPT" => "application/json" }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("pending")
  end

  it "returns a failed status payload with error markup" do
    profile.update!(
      training_block_generation_status: "failed",
      training_block_generation_error: "Generation failed"
    )

    get status_training_blocks_path, headers: { "ACCEPT" => "application/json" }

    expect(response).to have_http_status(:ok)
    payload = response.parsed_body
    expect(payload["status"]).to eq("failed")
    expect(payload["html"]).to include("Generation failed")
  end

  it "shows a generation notice after refresh via query param" do
    get training_blocks_path, params: { generation_notice: "Your new training block is ready and now visible below." }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your new training block is ready and now visible below.")
  end

  it "marks generation as failed when job enqueueing errors" do
    allow(GenerateTrainingBlockJob).to receive(:perform_later).and_raise(StandardError, "Queue down")

    post training_blocks_path,
      params: {
        start_date: Date.current.beginning_of_week(:monday).to_s,
        end_date: (Date.current.beginning_of_week(:monday) + 1.week).to_s
      },
      headers: { "ACCEPT" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:unprocessable_entity)
    profile.reload
    expect(profile.training_block_generation_status).to eq("failed")
    expect(profile.training_block_generation_error).to eq("Queue down")
    expect(response.body).to include("Generation failed")
  end

  it "completes the training block and removes future sessions" do
    travel_to Date.new(2026, 3, 25) do
      training_block = create(:training_block, climber_profile: profile, started_at: Date.current.beginning_of_week(:monday))
      current_week = create(:weekly_plan, training_block: training_block, climber_profile: profile, week_of: Date.current.beginning_of_week(:monday))
      future_week = create(:weekly_plan, training_block: training_block, climber_profile: profile, week_of: Date.current.beginning_of_week(:monday) + 1.week)

      past_session = create(:planned_session, weekly_plan: current_week, day_of_week: 0, status: :todo)
      future_session = create(:planned_session, weekly_plan: current_week, day_of_week: 5, status: :todo)
      completed_future_session = create(:planned_session, weekly_plan: current_week, day_of_week: 6, status: :completed)
      create(:planned_session, weekly_plan: future_week, day_of_week: 1, status: :todo)

      post complete_training_block_path(training_block)

      expect(response).to redirect_to(training_blocks_path)
      training_block.reload
      expect(training_block).to be_completed
      expect(training_block.ends_at).to eq(Date.current)

      expect(PlannedSession.exists?(past_session.id)).to be(true)
      expect(PlannedSession.exists?(future_session.id)).to be(false)
      expect(PlannedSession.exists?(completed_future_session.id)).to be(true)
      expect(WeeklyPlan.exists?(future_week.id)).to be(false)
    end
  end

  it "regenerates future sessions and redirects with a notice" do
    training_block = create(:training_block, climber_profile: profile)
    allow(Ai::TrainingBlockGenerator).to receive(:regenerate_future!)

    post regenerate_training_block_path(training_block), params: { comments: "More volume" }

    expect(Ai::TrainingBlockGenerator).to have_received(:regenerate_future!).with(training_block: training_block, comments: "More volume")
    expect(response).to redirect_to(training_blocks_path)
    expect(flash[:notice]).to eq("Future sessions regenerated!")
  end

  it "redirects with an alert when regeneration fails" do
    training_block = create(:training_block, climber_profile: profile)
    allow(Ai::TrainingBlockGenerator).to receive(:regenerate_future!).and_raise(Ai::Client::Error.new("No credits"))

    post regenerate_training_block_path(training_block)

    expect(response).to redirect_to(training_blocks_path)
    expect(flash[:alert]).to eq("Regeneration failed: No credits")
  end
end
