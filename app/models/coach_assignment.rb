class CoachAssignment < ApplicationRecord
  belongs_to :coach
  belongs_to :climber_profile

  enum status: { active: 0, paused: 1, ended: 2 }

  validates :status, presence: true

  scope :current, -> { where(status: :active) }
end
