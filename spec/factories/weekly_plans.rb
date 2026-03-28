FactoryBot.define do
  factory :weekly_plan do
    training_block { nil }
    climber_profile { nil }
    week_number { 1 }
    week_of { "2026-03-28" }
    status { 1 }
    ai_generated_plan { "" }
    coach_modified { false }
    coach_notes { "MyText" }
    summary { "MyText" }
  end
end
