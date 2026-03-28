FactoryBot.define do
  factory :ai_interaction do
    user { nil }
    interaction_type { 1 }
    provider { "MyString" }
    model { "MyString" }
    prompt { "MyText" }
    response { "MyText" }
    tokens_used { 1 }
    duration_ms { 1 }
    cost_cents { 1 }
  end
end
