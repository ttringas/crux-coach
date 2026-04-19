require "rails_helper"

RSpec.describe CalibrateSessionJob, type: :job do
  let(:profile) { create(:climber_profile) }
  let(:training_block) { create(:training_block, climber_profile: profile) }
  let(:weekly_plan) { create(:weekly_plan, training_block: training_block, climber_profile: profile) }
  let(:planned_session) do
    create(:planned_session,
      weekly_plan: weekly_plan,
      exercises: [ { "name" => "Limit Bouldering", "sets" => 5 } ])
  end
  let(:job_args) { { planned_session_id: planned_session.id, feedback: "Fingers a bit sore" } }

  before do
    ActiveJob::Base.queue_adapter = :test
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
  end

  it "enqueues the job" do
    expect { described_class.perform_later(**job_args) }
      .to have_enqueued_job(described_class).with(**job_args)
  end

  it "applies calibration, stores previous exercises, broadcasts" do
    allow(Ai::SessionCalibrator).to receive(:call).and_return(
      exercises: [ { "name" => "Easy Volume", "sets" => "3" } ],
      reasoning: "Lighter day for sore fingers",
      title: nil,
      description: nil,
      intensity: "low",
      estimated_duration_minutes: 60
    )

    described_class.perform_now(**job_args)

    planned_session.reload
    expect(planned_session.calibration_status).to eq("completed")
    expect(planned_session.previous_exercises).to eq([ { "name" => "Limit Bouldering", "sets" => 5 } ])
    expect(planned_session.exercises.first["name"]).to eq("Easy Volume")
    expect(planned_session.calibration_reasoning).to include("Lighter day")
    expect(planned_session.intensity).to eq("low")

    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).at_least(:once)
  end

  it "marks failed and broadcasts on ArgumentError" do
    allow(Ai::SessionCalibrator).to receive(:call).and_raise(ArgumentError.new("bad input"))

    described_class.perform_now(**job_args)

    planned_session.reload
    expect(planned_session.calibration_status).to eq("failed")
    expect(planned_session.calibration_error).to eq("bad input")
  end

  it "marks failed with generic message on unexpected error" do
    allow(Ai::SessionCalibrator).to receive(:call).and_raise(RuntimeError.new("boom"))

    described_class.perform_now(**job_args)

    planned_session.reload
    expect(planned_session.calibration_status).to eq("failed")
    expect(planned_session.calibration_error).to match(/Calibration failed unexpectedly/)
  end

  it "does not permanently fail on first Ai::Client::Error (retryable)" do
    allow(Ai::SessionCalibrator).to receive(:call).and_raise(Ai::Client::Error.new("transient"))

    described_class.perform_now(**job_args)

    expect(planned_session.reload.calibration_status).not_to eq("failed")
  end

  it "no-ops if planned_session is missing" do
    expect(Ai::SessionCalibrator).not_to receive(:call)
    described_class.perform_now(planned_session_id: -1, feedback: "")
  end

  it "preserves the original previous_exercises across recalibration" do
    original = [ { "name" => "Limit Bouldering", "sets" => 5 } ]
    allow(Ai::SessionCalibrator).to receive(:call).and_return(
      exercises: [ { "name" => "First Calibration" } ],
      reasoning: "x", title: nil, description: nil, intensity: nil, estimated_duration_minutes: nil
    )
    described_class.perform_now(**job_args)

    allow(Ai::SessionCalibrator).to receive(:call).and_return(
      exercises: [ { "name" => "Second Calibration" } ],
      reasoning: "y", title: nil, description: nil, intensity: nil, estimated_duration_minutes: nil
    )
    described_class.perform_now(**job_args)

    expect(planned_session.reload.previous_exercises).to eq(original)
    expect(planned_session.exercises.first["name"]).to eq("Second Calibration")
  end
end
