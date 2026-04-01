class ClimberProfile < ApplicationRecord
  belongs_to :user

  has_many :training_blocks, dependent: :destroy
  has_many :weekly_plans, dependent: :destroy
  has_many :planned_sessions, through: :weekly_plans
  has_many :session_logs, dependent: :destroy
  has_many :climbing_benchmarks, dependent: :destroy
  has_many :coach_assignments, dependent: :destroy
  has_many :coaches, through: :coach_assignments

  validates :height_inches, :wingspan_inches, :years_climbing, :training_age_months,
            :weekly_training_days, :session_duration_minutes,
            numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :weight_lbs, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :weekly_training_days, numericality: { less_than_or_equal_to: 7, allow_nil: true }

  scope :onboarded, -> { where(onboarding_completed: true) }
  scope :not_onboarded, -> { where(onboarding_completed: false) }
end
