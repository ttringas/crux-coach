FactoryBot.define do
  factory :coach_assignment do
    coach { nil }
    climber_profile { nil }
    status { 1 }
    started_at { "2026-03-28 19:48:23" }
    ended_at { "2026-03-28 19:48:23" }
    coach_notes { "MyText" }
  end
end
