class PlannedSession < ApplicationRecord
  belongs_to :weekly_plan
  has_one :session_log, dependent: :nullify

  enum :session_type, {
    climbing: 0,
    board: 1,
    hangboard: 2,
    strength: 3,
    cardio: 4,
    mobility: 5,
    rest: 6,
    outdoor: 7
  }

  enum :intensity, { low: 0, moderate: 1, high: 2, max_effort: 3 }
  enum :status, { todo: 0, in_progress: 1, completed: 2, skipped: 3 }

  validates :day_of_week, inclusion: { in: 0..6 }
  validates :title, presence: true
  validates :estimated_duration_minutes, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :session_type, :intensity, presence: true

  def ensure_session_log!
    return unless completed?

    log = session_log || weekly_plan.climber_profile.session_logs.new(planned_session: self)
    log.session_type = session_type
    log.date = (completed_at || Time.zone.now).to_date
    log.duration_minutes = estimated_duration_minutes
    log.perceived_exertion = perceived_exertion
    log.energy_level = energy_level
    log.finger_soreness = finger_soreness
    log.general_soreness = general_soreness
    log.notes = session_notes
    log.exercises_logged = exercises_logged_payload
    log.save!
  end

  def exercises_logged_payload
    return [] if exercises.blank?

    logs_by_index = exercise_logs.index_by { |log| log["exercise_index"].to_i }

    exercises.each_with_index.filter_map do |exercise, index|
      log = logs_by_index[index] || {}
      has_data = log["completed"].present? || log["actual_sets"].present? || log["actual_reps"].present? ||
                 log["actual_weight"].present? || log["actual_duration"].present? || log["notes"].present?
      next unless has_data

      {
        name: exercise["name"] || exercise["title"] || "Exercise",
        sets: log["actual_sets"],
        reps: log["actual_reps"],
        weight: log["actual_weight"],
        duration: log["actual_duration"],
        notes: log["notes"]
      }
    end
  end
end
