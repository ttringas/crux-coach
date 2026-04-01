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
  end

  it "broadcasts an error when generation fails" do
    allow(Ai::TrainingBlockGenerator).to receive(:call).and_raise(Ai::Client::Error.new("boom"))

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
      profile,
      target: ActionView::RecordIdentifier.dom_id(profile, :training_block_generation),
      partial: "training_blocks/generation_error",
      locals: { profile: profile, message: "boom" }
    )

    described_class.perform_now(**job_args)
  end
end
