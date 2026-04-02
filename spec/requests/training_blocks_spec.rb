require "rails_helper"

RSpec.describe "TrainingBlocks", type: :request do
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

  it "shows a generation notice after refresh via query param" do
    get training_blocks_path, params: { generation_notice: "Your new training block is ready and now visible below." }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Your new training block is ready and now visible below.")
  end
end
