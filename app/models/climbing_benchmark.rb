class ClimbingBenchmark < ApplicationRecord
  self.table_name = "benchmarks"

  belongs_to :climber_profile
  has_many :climbing_benchmark_histories, foreign_key: :benchmark_id, dependent: :destroy

  validates :benchmark_key, presence: true
  validates :benchmark_key, uniqueness: { scope: :climber_profile_id }

  BENCHMARK_DEFINITIONS = [
    # Finger Strength
    { key: "max_weighted_hang_20mm", label: "Max Weighted Hang — 20mm Edge", category: "Finger Strength", unit: "lbs", description: "Added weight for 7-10s max hang on 20mm edge" },
    { key: "max_weighted_hang_10mm", label: "Max Weighted Hang — 10mm Edge", category: "Finger Strength", unit: "lbs", description: "Added weight for 7-10s max hang on 10mm edge" },
    { key: "max_hang_duration_20mm", label: "Max Hang Duration — BW 20mm", category: "Finger Strength", unit: "seconds", description: "Bodyweight dead hang time on 20mm edge" },
    { key: "max_hang_duration_10mm", label: "Max Hang Duration — BW 10mm", category: "Finger Strength", unit: "seconds", description: "Bodyweight dead hang time on 10mm edge" },
    { key: "critical_force", label: "Critical Force", category: "Finger Strength", unit: "lbs", description: "Repeater test critical force value" },

    # Climbing Grades
    { key: "indoor_boulder_max", label: "Indoor Bouldering — Max (Redpoint)", category: "Climbing Grades", unit: "grade", description: "Hardest indoor boulder sent" },
    { key: "indoor_boulder_onsight", label: "Indoor Bouldering — Onsight", category: "Climbing Grades", unit: "grade", description: "Hardest indoor boulder onsighted" },
    { key: "indoor_sport_max", label: "Indoor Sport — Max (Redpoint)", category: "Climbing Grades", unit: "grade", description: "Hardest indoor sport route sent" },
    { key: "indoor_sport_onsight", label: "Indoor Sport — Onsight", category: "Climbing Grades", unit: "grade", description: "Hardest indoor sport route onsighted" },
    { key: "outdoor_boulder_max", label: "Outdoor Bouldering — Max (Redpoint)", category: "Climbing Grades", unit: "grade", description: "Hardest outdoor boulder sent" },
    { key: "outdoor_sport_max", label: "Outdoor Sport — Max (Redpoint)", category: "Climbing Grades", unit: "grade", description: "Hardest outdoor sport route sent" },
    { key: "outdoor_sport_onsight", label: "Outdoor Sport — Onsight", category: "Climbing Grades", unit: "grade", description: "Hardest outdoor sport route onsighted" },

    # Upper Body Strength
    { key: "max_pullups", label: "Max Bodyweight Pull-ups", category: "Upper Body Strength", unit: "count", description: "Maximum consecutive bodyweight pull-ups" },
    { key: "max_weighted_pullup", label: "Max Weighted Pull-up", category: "Upper Body Strength", unit: "lbs", description: "Added weight for 1 rep" },
    { key: "lockoff_90", label: "Lock-off Hold — 90°", category: "Upper Body Strength", unit: "seconds", description: "Max hold time at 90° elbow bend" },
    { key: "lockoff_full", label: "Lock-off Hold — Full Lock", category: "Upper Body Strength", unit: "seconds", description: "Max hold time at full lock-off" },

    # General Strength
    { key: "deadlift_1rm", label: "Deadlift — 1RM", category: "General Strength", unit: "lbs", description: "One-rep max deadlift" },
    { key: "bench_press_1rm", label: "Bench Press — 1RM", category: "General Strength", unit: "lbs", description: "One-rep max bench press" },
    { key: "overhead_press_1rm", label: "Overhead Press — 1RM", category: "General Strength", unit: "lbs", description: "One-rep max overhead press" },
    { key: "squat_1rm", label: "Squat — 1RM", category: "General Strength", unit: "lbs", description: "One-rep max squat" },

    # Power & Explosiveness
    { key: "campus_max_span", label: "Campus Board — Max Span", category: "Power & Explosiveness", unit: "rungs", description: "e.g. 1-5 on small rungs" },
    { key: "campus_max_laps", label: "Campus Board — Max Laps", category: "Power & Explosiveness", unit: "count", description: "Maximum consecutive campus laps" },
    { key: "box_jump_height", label: "Box Jump Height", category: "Power & Explosiveness", unit: "inches", description: "Maximum box jump height" },

    # Endurance
    { key: "four_by_four_grade", label: "4x4s — Grade Used", category: "Endurance", unit: "grade", description: "Grade used for 4x4 completion" },
    { key: "arc_duration", label: "ARC Session Duration", category: "Endurance", unit: "minutes", description: "Continuous climbing at threshold" },
    { key: "max_lead_laps", label: "Max Lead Wall Laps", category: "Endurance", unit: "count", description: "Continuous laps without resting" },

    # Body Composition
    { key: "bodyweight", label: "Bodyweight", category: "Body Composition", unit: "lbs", description: "Current bodyweight" },
    { key: "body_fat_pct", label: "Body Fat %", category: "Body Composition", unit: "%", description: "Current body fat percentage" }
  ].freeze

  DEFINITIONS_BY_KEY = BENCHMARK_DEFINITIONS.index_by { |d| d[:key] }.freeze
  CATEGORIES = BENCHMARK_DEFINITIONS.map { |d| d[:category] }.uniq.freeze

  def definition
    DEFINITIONS_BY_KEY[benchmark_key]
  end

  def label
    definition&.dig(:label) || benchmark_key.titleize
  end
end
