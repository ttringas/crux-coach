class PlannedSession < ApplicationRecord
  belongs_to :weekly_plan

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

  validates :day_of_week, inclusion: { in: 0..6 }
  validates :title, presence: true
  validates :estimated_duration_minutes, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :session_type, :intensity, presence: true
end
