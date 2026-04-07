class GenerateTrainingBlockJob < ApplicationJob
  queue_as :default

  # Retry transient AI errors with exponential backoff (wait 2s, 4s, then give up)
  retry_on Ai::Client::Error, wait: ->(executions) { (2**executions).seconds }, attempts: 3 do |job, error|
    # This block runs after all retries are exhausted
    profile = ClimberProfile.find_by(id: job.arguments.first[:climber_profile_id])
    if profile
      profile.update(
        training_block_generation_status: "failed",
        training_block_generation_error: error.message,
        training_block_generation_training_block_id: nil
      )
      job.send(:broadcast_error, profile, error.message)
    end
  end

  discard_on ActiveJob::DeserializationError

  def perform(climber_profile_id:, start_date:, end_date:, weeks_planned:, comments:, training_days:, activities:)
    profile = ClimberProfile.find_by(id: climber_profile_id)
    return unless profile

    # Update started_at so timeout detection knows the job is actively running
    profile.update_column(:training_block_generation_started_at, Time.current)

    parsed_start = parse_date(start_date)
    parsed_end = parse_date(end_date)
    parsed_weeks = weeks_planned.to_i

    training_block = Ai::TrainingBlockGenerator.call(
      climber_profile: profile,
      start_date: parsed_start,
      end_date: parsed_end,
      weeks_planned: parsed_weeks,
      comments: comments.to_s,
      training_days: Array(training_days).select(&:present?),
      activities: Array(activities).select(&:present?)
    )

    profile.update(onboarding_completed: true) unless profile.onboarding_completed?
    profile.update(
      training_block_generation_status: "completed",
      training_block_generation_error: nil,
      training_block_generation_training_block_id: training_block.id
    )

    broadcast_complete(profile, training_block)
    send_completion_email(profile, training_block)
  rescue ArgumentError => e
    mark_failed(profile, e.message)
    broadcast_error(profile, e.message)
  rescue StandardError => e
    # Don't catch Ai::Client::Error here — retry_on handles that
    raise if e.is_a?(Ai::Client::Error)

    mark_failed(profile, "Something went wrong while generating your plan. Please try again.")
    broadcast_error(profile, "Something went wrong while generating your plan. Please try again.")
    Rails.logger.error("GenerateTrainingBlockJob failed: #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
  end

  private

  def mark_failed(profile, message)
    profile&.update(
      training_block_generation_status: "failed",
      training_block_generation_error: message,
      training_block_generation_training_block_id: nil
    )
  end

  def parse_date(value)
    return value if value.is_a?(Date)

    Date.parse(value.to_s)
  end

  def broadcast_complete(profile, training_block)
    return unless turbo_broadcast_available?

    Turbo::StreamsChannel.broadcast_replace_to(
      profile,
      target: generation_target(profile),
      partial: "training_blocks/generation_complete",
      locals: { training_block: training_block }
    )
  end

  def broadcast_error(profile, message)
    return unless profile
    return unless turbo_broadcast_available?

    Turbo::StreamsChannel.broadcast_replace_to(
      profile,
      target: generation_target(profile),
      partial: "training_blocks/generation_error",
      locals: { profile: profile, message: message }
    )
  end

  def send_completion_email(profile, training_block)
    user = profile.user
    return unless user&.email.present?

    TrainingBlockMailer.generation_complete(user, training_block).deliver_later
  rescue StandardError => e
    Rails.logger.error("TrainingBlockMailer failed: #{e.class} #{e.message}")
  end

  def turbo_broadcast_available?
    defined?(ActionCable)
  end

  def generation_target(profile)
    ActionView::RecordIdentifier.dom_id(profile, :training_block_generation)
  end
end
