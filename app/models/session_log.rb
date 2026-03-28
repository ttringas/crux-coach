class SessionLog < ApplicationRecord
  belongs_to :climber_profile
  belongs_to :planned_session, optional: true

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

  validates :date, presence: true
  validates :duration_minutes, numericality: { greater_than: 0, allow_nil: true }
  validates :perceived_exertion, inclusion: { in: 1..10, allow_nil: true }
  validates :energy_level, :skin_condition, :finger_soreness, :general_soreness, :mood,
            inclusion: { in: 1..5, allow_nil: true }
  validates :session_type, presence: true

  scope :recent, -> { order(date: :desc) }
end
