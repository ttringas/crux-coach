FactoryBot.define do
  factory :climbing_benchmark do
    association :climber_profile
    benchmark_key { "max_weighted_hang_20mm" }
    value { "45" }
    unit { "lbs" }
    tested_at { Date.current }
    notes { "Felt strong" }
  end
end
