class ClimberProfile < ApplicationRecord
  belongs_to :user

  has_many :training_blocks, dependent: :destroy
  has_many :weekly_plans, dependent: :destroy
  has_many :planned_sessions, through: :weekly_plans
  has_many :session_logs, dependent: :destroy
  has_many :climbing_benchmarks, dependent: :destroy
  has_many :coach_assignments, dependent: :destroy
  has_many :coaches, through: :coach_assignments

  EQUIPMENT_OPTIONS = {
    "hangboard" => "Hangboard",
    "training_board" => "Training Board",
    "campus_board" => "Campus board",
    "spray_wall" => "Spray wall",
    "systems_wall" => "Systems wall",
    "pull_up_bar" => "Pull up bar",
    "rings_trx" => "Rings/TRX",
    "weights" => "Weights",
    "lifting_block" => "Lifting Block",
    "resistance_bands" => "Resistance bands",
    "treadmill_bike_rower" => "Treadmill/Bike/Rower"
  }.freeze

  validates :height_inches, :wingspan_inches, :years_climbing, :training_age_years,
            :weekly_training_days, :session_duration_minutes,
            numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :weight_lbs, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :weekly_training_days, numericality: { less_than_or_equal_to: 7, allow_nil: true }

  scope :onboarded, -> { where(onboarding_completed: true) }
  scope :not_onboarded, -> { where(onboarding_completed: false) }

  def available_equipment_labels
    available_equipment.map { |item| EQUIPMENT_OPTIONS[item] || item.humanize }
  end
end
