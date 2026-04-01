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
    expect(response.body).to include("Generating your training plan")
  end
end
