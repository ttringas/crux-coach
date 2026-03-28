FactoryBot.define do
  factory :coach do
    user { nil }
    bio { "MyText" }
    specialties { "MyText" }
    years_coaching { 1 }
    max_grade_boulder { "MyString" }
    max_grade_sport { "MyString" }
    rate_per_month { "9.99" }
    accepting_athletes { false }
  end
end
