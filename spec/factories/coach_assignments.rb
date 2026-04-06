FactoryBot.define do
  factory :coach_assignment do
    association :coach
    association :climber_profile
    status { :active }
    started_at { Time.current }
    ended_at { nil }
    coach_notes { "Looking forward to working together" }
  end
end
