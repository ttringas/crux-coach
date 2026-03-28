FactoryBot.define do
  factory :planned_session do
    weekly_plan { nil }
    day_of_week { 1 }
    session_type { 1 }
    title { "MyString" }
    description { "MyText" }
    estimated_duration_minutes { 1 }
    intensity { 1 }
    exercises { "" }
  end
end
