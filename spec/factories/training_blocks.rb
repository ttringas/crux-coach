FactoryBot.define do
  factory :training_block do
    climber_profile { nil }
    name { "MyString" }
    focus { 1 }
    weeks_planned { 1 }
    week_number { 1 }
    started_at { "2026-03-28" }
    ends_at { "2026-03-28" }
    status { 1 }
    ai_reasoning { "MyText" }
  end
end
