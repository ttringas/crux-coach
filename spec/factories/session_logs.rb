FactoryBot.define do
  factory :session_log do
    association :climber_profile
    planned_session { nil }
    session_type { :climbing }
    date { Date.current }
    duration_minutes { 60 }
    perceived_exertion { 5 }
    energy_level { 3 }
    skin_condition { 3 }
    finger_soreness { 2 }
    general_soreness { 2 }
    mood { 4 }
    notes { "Good session" }
    raw_input { nil }
    structured_data { {} }
    climbs_logged { [] }
    exercises_logged { [] }
  end
end
