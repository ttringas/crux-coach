FactoryBot.define do
  factory :planned_session do
    association :weekly_plan
    day_of_week { 1 }
    session_type { :climbing }
    title { "Hangboard Session" }
    description { "Some details" }
    estimated_duration_minutes { 60 }
    intensity { :moderate }
    exercises { [ { "name" => "Repeaters", "sets" => 3, "reps" => 6 } ] }
  end
end
