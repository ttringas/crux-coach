FactoryBot.define do
  factory :climber_profile do
    association :user
    height_inches { 70 }
    wingspan_inches { 70 }
    weight_lbs { "150.00" }
    years_climbing { 3 }
    training_age_months { 12 }
    current_max_boulder_grade { "V5" }
    current_max_sport_grade { "5.11a" }
    comfortable_boulder_grade { "V3" }
    comfortable_sport_grade { "5.10a" }
    preferred_disciplines { [] }
    available_equipment { [] }
    weekly_training_days { 3 }
    session_duration_minutes { 60 }
    goals_short_term { "Improve endurance" }
    goals_long_term { "Climb V8" }
    injuries { [] }
    style_strengths { [] }
    style_weaknesses { [] }
    additional_context { "None" }
    onboarding_completed { false }
  end
end
