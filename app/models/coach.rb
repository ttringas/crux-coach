class Coach < ApplicationRecord
  belongs_to :user

  has_many :coach_assignments, dependent: :destroy
  has_many :climber_profiles, through: :coach_assignments

  validates :years_coaching, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :rate_per_month, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :accepting, -> { where(accepting_athletes: true) }
end
