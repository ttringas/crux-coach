class ClimbingBenchmarkHistory < ApplicationRecord
  self.table_name = "benchmark_histories"

  belongs_to :climbing_benchmark, foreign_key: :benchmark_id
end
