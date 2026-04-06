FactoryBot.define do
  factory :ai_interaction do
    association :user
    interaction_type { :plan_generation }
    provider { "anthropic" }
    model { "claude-sonnet-4-20250514" }
    prompt { "Generate a training plan" }
    response { '{"sessions": []}' }
    tokens_used { 500 }
    duration_ms { 1200 }
    cost_cents { 2 }
  end
end
