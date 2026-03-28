FactoryBot.define do
  factory :climber_profile do
    user { nil }
    height_inches { 1 }
    wingspan_inches { 1 }
    weight_lbs { "9.99" }
    years_climbing { 1 }
    training_age_months { 1 }
    current_max_boulder_grade { "MyString" }
    current_max_sport_grade { "MyString" }
    comfortable_boulder_grade { "MyString" }
    comfortable_sport_grade { "MyString" }
    preferred_disciplines { "MyText" }
    available_equipment { "MyText" }
    weekly_training_days { 1 }
    session_duration_minutes { 1 }
    goals_short_term { "MyText" }
    goals_long_term { "MyText" }
    injuries { "" }
    style_strengths { "MyText" }
    style_weaknesses { "MyText" }
    additional_context { "MyText" }
    onboarding_completed { false }
  end
end
