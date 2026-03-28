class AiInteraction < ApplicationRecord
  belongs_to :user

  enum interaction_type: {
    plan_generation: 0,
    session_parsing: 1,
    profile_analysis: 2,
    coach_suggestion: 3
  }

  validates :interaction_type, :provider, :model, presence: true
  validates :prompt, :response, presence: true
  validates :tokens_used, :duration_ms, :cost_cents,
            numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :recent, -> { order(created_at: :desc) }
end
