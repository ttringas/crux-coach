require "rails_helper"

RSpec.describe GenerateTrainingBlockJob, type: :job do
  let(:profile) { create(:climber_profile) }
  let(:start_date) { Date.current.beginning_of_week(:monday) }
  let(:end_date) { start_date + 4.weeks }
  let(:weeks_planned) { 4 }
  let(:job_args) do
    {
      climber_profile_id: profile.id,
      start_date: start_date,
      end_date: end_date,
      weeks_planned: weeks_planned,
      comments: "Focus on power",
      training_days: [ "Monday", "Wednesday" ],
      activities: [ "Bouldering" ]
    }
  end

  before do
    ActiveJob::Base.queue_adapter = :test
  end

  it "enqueues the job" do
    expect { described_class.perform_later(**job_args) }
      .to have_enqueued_job(described_class).with(**job_args)
  end

  it "calls the generator and broadcasts completion" do
    training_block = create(:training_block, climber_profile: profile, started_at: start_date, ends_at: end_date)
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_return(training_block)

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      profile,
      target: ActionView::RecordIdentifier.dom_id(profile, :training_block_generation),
      partial: "training_blocks/generation_complete",
      locals: { training_block: training_block }
    )

    described_class.perform_now(**job_args)

    expect(profile.reload.training_block_generation_status).to eq("completed")
    expect(profile.training_block_generation_training_block_id).to eq(training_block.id)
  end

  it "marks as failed and broadcasts error on ArgumentError (non-retryable)" do
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_raise(ArgumentError.new("bad input"))

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      profile,
      target: ActionView::RecordIdentifier.dom_id(profile, :training_block_generation),
      partial: "training_blocks/generation_error",
      locals: { profile: profile, message: "bad input" }
    )

    described_class.perform_now(**job_args)

    expect(profile.reload.training_block_generation_status).to eq("failed")
    expect(profile.training_block_generation_error).to eq("bad input")
  end

  it "updates generation_started_at when the job starts" do
    training_block = create(:training_block, climber_profile: profile, started_at: start_date, ends_at: end_date)
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_return(training_block)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    expect(profile.training_block_generation_started_at).to be_nil

    described_class.perform_now(**job_args)

    expect(profile.reload.training_block_generation_started_at).to be_present
    expect(profile.training_block_generation_started_at).to be_within(5.seconds).of(Time.current)
  end

  it "enqueues a completion email on success" do
    training_block = create(:training_block, climber_profile: profile, started_at: start_date, ends_at: end_date)
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_return(training_block)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    expect {
      described_class.perform_now(**job_args)
    }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
  end

  it "does not permanently fail on first Ai::Client::Error (retryable)" do
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_raise(Ai::Client::Error.new("transient"))

    # retry_on enqueues a retry and doesn't raise to the caller
    described_class.perform_now(**job_args)

    # Should NOT be marked as failed on first attempt — retry_on handles it
    expect(profile.reload.training_block_generation_status).not_to eq("failed")
  end

  it "handles StandardError with generic message" do
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_raise(RuntimeError.new("unexpected"))
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    described_class.perform_now(**job_args)

    expect(profile.reload.training_block_generation_status).to eq("failed")
    expect(profile.training_block_generation_error).to eq("Something went wrong while generating your plan. Please try again.")
  end

  it "does nothing if profile is not found" do
    expect(Ai::TrainingBlockGenerator).not_to receive(:call)

    described_class.perform_now(**job_args.merge(climber_profile_id: -1))
  end
end
