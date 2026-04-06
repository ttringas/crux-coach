FactoryBot.define do
  factory :climbing_benchmark_history do
    association :climbing_benchmark
    value { "40" }
    tested_at { 1.month.ago.to_date }
    notes { "Previous test" }
  end
end
