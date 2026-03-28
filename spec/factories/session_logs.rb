FactoryBot.define do
  factory :session_log do
    climber_profile { nil }
    planned_session { nil }
    session_type { 1 }
    date { "2026-03-28" }
    duration_minutes { 1 }
    perceived_exertion { 1 }
    energy_level { 1 }
    skin_condition { 1 }
    finger_soreness { 1 }
    general_soreness { 1 }
    mood { 1 }
    notes { "MyText" }
    raw_input { "MyText" }
    structured_data { "" }
    climbs_logged { "" }
    exercises_logged { "" }
  end
end
