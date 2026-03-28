class WeeklyPlan < ApplicationRecord
  belongs_to :training_block
  belongs_to :climber_profile

  has_many :planned_sessions, dependent: :destroy

  enum :status, { draft: 0, active: 1, completed: 2 }

  validates :week_number, numericality: { greater_than: 0, allow_nil: true }
  validates :week_of, presence: true
  validates :status, presence: true

  scope :current, -> { where(status: :active) }
end
