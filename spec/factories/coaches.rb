FactoryBot.define do
  factory :coach do
    association :user, role: :coach
    bio { "Experienced climbing coach" }
    specialties { [ "bouldering", "sport climbing" ] }
    years_coaching { 5 }
    max_grade_boulder { "V10" }
    max_grade_sport { "5.13a" }
    rate_per_month { 99.99 }
    accepting_athletes { true }
  end
end
