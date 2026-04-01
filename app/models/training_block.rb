class TrainingBlock < ApplicationRecord
  belongs_to :climber_profile

  has_many :weekly_plans, dependent: :destroy

  enum :focus, {
    power: 0,
    power_endurance: 1,
    endurance: 2,
    technique: 3,
    base: 4,
    deload: 5,
    project: 6
  }

  enum :status, { active: 0, completed: 1, abandoned: 2 }

  validates :name, presence: true
  validates :focus, :status, presence: true
  validates :weeks_planned, numericality: { greater_than: 0, less_than_or_equal_to: 12, allow_nil: true }
  validates :week_number, numericality: { greater_than: 0, allow_nil: true }

  scope :current, -> { where(status: :active) }
end
