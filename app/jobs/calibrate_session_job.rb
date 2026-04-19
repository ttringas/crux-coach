class CalibrateSessionJob < ApplicationJob
  queue_as :default

  retry_on Ai::Client::Error, wait: ->(executions) { (2**executions).seconds }, attempts: 3 do |job, error|
    session = PlannedSession.find_by(id: job.arguments.first[:planned_session_id])
    next unless session

    session.update(
      calibration_status: "failed",
      calibration_error: error.message,
      calibration_completed_at: Time.current
    )
    job.send(:broadcast_status, session)
  end

  discard_on ActiveJob::DeserializationError

  def perform(planned_session_id:, feedback:)
    session = PlannedSession.find_by(id: planned_session_id)
    return unless session

    session.update!(
      calibration_status: "in_progress",
      calibration_error: nil,
      calibration_requested_at: session.calibration_requested_at || Time.current
    )
    broadcast_status(session)

    result = Ai::SessionCalibrator.call(
      planned_session: session,
      feedback: feedback.to_s
    )

    apply_calibration!(session, result)
    broadcast_status(session)
  rescue ArgumentError => e
    mark_failed(session, e.message)
    broadcast_status(session)
  rescue StandardError => e
    raise if e.is_a?(Ai::Client::Error)

    mark_failed(session, "Calibration failed unexpectedly. Please try again.")
    Rails.logger.error("CalibrateSessionJob failed: #{e.class} #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
    broadcast_status(session) if session
  end

  private

  def apply_calibration!(session, result)
    PlannedSession.transaction do
      session.previous_exercises = session.exercises if session.previous_exercises.blank?
      session.exercises = result[:exercises]
      session.calibration_reasoning = result[:reasoning]
      session.calibration_status = "completed"
      session.calibration_error = nil
      session.calibration_completed_at = Time.current

      session.title = result[:title] if result[:title].present?
      session.description = result[:description] if result[:description].present?
      session.intensity = result[:intensity] if result[:intensity].present? && PlannedSession.intensities.key?(result[:intensity])
      if result[:estimated_duration_minutes].present? && result[:estimated_duration_minutes].to_i > 0
        session.estimated_duration_minutes = result[:estimated_duration_minutes].to_i
      end

      session.save!
    end
  end

  def mark_failed(session, message)
    return unless session

    session.update(
      calibration_status: "failed",
      calibration_error: message,
      calibration_completed_at: Time.current
    )
  end

  def broadcast_status(session)
    return unless session
    return unless defined?(ActionCable)

    Turbo::StreamsChannel.broadcast_replace_to(
      session,
      target: ActionView::RecordIdentifier.dom_id(session, :calibration),
      partial: "planned_sessions/calibration_panel",
      locals: { planned_session: session }
    )
  end
end
