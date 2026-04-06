# frozen_string_literal: true

require "json"

module Ai
  module Prompts
    class PlanGenerator
      def self.build(climber_profile:, training_block: nil, session_logs: nil, training_days: nil, activities: nil)
        training_block ||= climber_profile.training_blocks.current.first
        session_logs ||= recent_session_logs(climber_profile)

        {
          system: system_prompt,
          user: user_prompt(climber_profile, training_block, session_logs, training_days, activities)
        }
      end

      def self.system_prompt
        <<~TEXT
          You are an expert climbing coach and sport scientist. Build safe, effective weekly plans using:
          - Periodization: balance volume and intensity, progressive overload, and planned recovery/deloads.
          - Finger load management: avoid back-to-back high finger intensity; balance crimp/pinch/open-hand; manage board/hangboard volume.
          - Recovery: respect sleep, soreness, skin condition, and reported fatigue. Include rest/mobility as needed.
          - Session types: climbing (gym/outdoor), board, hangboard, strength, cardio, mobility; match to goals.
          - Risk control: honor injuries and avoid aggravating patterns. Replace risky work with safe alternatives.
          - Specificity: prescribe concrete session structure, exercises, sets/reps/rest, and intensity guidance.
          - BENCHMARK-BASED CALIBRATION: When the climber has benchmark data, you MUST use it to set specific, personalized targets:
            - Hangboard: Use max_weighted_hang values to prescribe hang protocols (e.g. if max_weighted_hang_20mm is +45 lbs, prescribe working sets at 70-85% of that). Use max_hang_duration to calibrate timed hangs.
            - Pull-ups: Use max_weighted_pullup to set target_weight for weighted pull-ups (typically 70-85% of max for working sets). Use max_pullups to calibrate bodyweight rep targets.
            - Lockoffs: Use lockoff_90 and lockoff_full benchmarks to set hold durations for lock-off training.
            - General strength: Use deadlift_1rm, bench_press_1rm, overhead_press_1rm, squat_1rm to prescribe working weights (typically 65-85% of 1RM depending on the training phase).
            - Climbing grades: Use current max and onsight grades to set target_grade for climbing sessions (e.g. limit bouldering at max grade, volume climbing 2-3 grades below max, onsight practice at onsight grade).
            - Power: Use campus_max_span and box_jump_height to calibrate explosive training.
            - Endurance: Use four_by_four_grade and arc_duration to set endurance session parameters.
            - Body composition: Use bodyweight to calculate relative strength targets and added weight for weighted exercises.
            - If a benchmark has historical progression data, use the trend to inform whether to push intensity or consolidate.
            - Always include the actual weight, grade, or duration values in the exercise prescription (target_weight, target_grade, target_reps) — do NOT leave them as null when benchmark data is available.
          - Exercise fields: Use the new exercise schema. For each exercise, set `target_reps` (numeric value), `rep_unit` (one of: reps, seconds, minutes, problems, routes, attempts), `target_grade` (climbing grade like "V2-V3" when applicable, null otherwise), and `target_weight` (for strength exercises, null otherwise). Also keep `reps` as a backward-compatible copy of `target_reps`. Examples:
            - Climbing: {"name": "Boulder Problems", "sets": 10, "target_reps": "4", "rep_unit": "problems", "target_grade": "V3-V4", "reps": "4", "rest": "2 min", "notes": "Focus on technique"}
            - Hangboard: {"name": "20mm Edge Hangs", "sets": 6, "target_reps": "7", "rep_unit": "seconds", "reps": "7", "rest": "3 min", "notes": "+30 lbs based on max hang benchmark"}
            - Strength: {"name": "Weighted Pull-ups", "sets": 3, "target_reps": "5", "rep_unit": "reps", "target_weight": "+25 lbs", "reps": "5", "rest": "3 min", "notes": "~75% of max weighted pull-up"}
            - Timed: {"name": "Continuous Climbing", "sets": 3, "target_reps": "8", "rep_unit": "minutes", "reps": "8", "rest": "5 min"}
          - CRITICAL CONSTRAINTS: You MUST strictly respect the scheduling_constraints provided. Only schedule sessions on days listed in training_days. Only include activities listed in activities. If an activity is not in the list, do NOT include it under any circumstances. Violating these constraints is a critical error.

          Output must be valid JSON only. No markdown. Follow the exact schema provided by the user prompt.
        TEXT
      end

      def self.user_prompt(climber_profile, training_block, session_logs, training_days, activities)
        resolved_training_days = Array(training_days).presence || (0..6).to_a
        resolved_activities = Array(activities).presence || %w[
          bouldering
          rope_climbing
          board_climbing
          hangboarding
          strength_training
          cardio
          mobility
        ]

        payload = {
          climber_profile: climber_profile_payload(climber_profile),
          training_block: training_block_payload(training_block),
          previous_training_blocks: previous_blocks_payload(climber_profile),
          benchmarks: benchmarks_payload(climber_profile),
          all_session_logs: session_logs_payload(session_logs),
          scheduling_constraints: {
            training_days: resolved_training_days,
            allowed_activities: resolved_activities,
            allowed_session_types: map_activities_to_session_types(resolved_activities),
            rules: [
              "ONLY schedule sessions on the specified training_days (0=Monday). All other days MUST have zero sessions.",
              "ONLY use session_type values from the allowed_session_types list. NEVER use a session_type not in that list.",
              "The allowed_session_types list is EXHAUSTIVE. If 'board' is not listed, you CANNOT create any board sessions. If 'hangboard' is not listed, you CANNOT create any hangboard sessions. This is a HARD constraint with zero exceptions.",
              "Activity to session_type mapping: bouldering→climbing, rope_climbing→climbing, board_climbing→board, hangboarding→hangboard, strength_training→strength, cardio→cardio, mobility→mobility"
            ]
          },
          instructions: {
            output_schema: {
              summary: "string",
              sessions: [
                {
                  day_of_week: "0-6 (0=Monday)",
                  session_type: "climbing|board|hangboard|strength|cardio|mobility|rest|outdoor",
                  title: "string",
                  description: "string",
                  estimated_duration_minutes: "integer",
                  intensity: "low|moderate|high|max",
                  exercises: [
                    {
                      name: "string",
                      sets: "string or integer",
                      target_reps: "string or integer — the numeric target value",
                      rep_unit: "reps|seconds|minutes|problems|routes|attempts",
                      target_grade: "string or null — climbing grade (e.g. V3-V4) when applicable",
                      target_weight: "string or null — weight for strength exercises",
                      reps: "string or integer — backward compat, same as target_reps",
                      duration: "string — overall exercise duration if relevant",
                      rest: "string",
                      notes: "string"
                    }
                  ]
                }
              ]
            }
          }
        }

        <<~TEXT
          Build next week's training plan based on the following data. Return JSON matching the schema exactly.

          #{JSON.pretty_generate(payload)}
        TEXT
      end

      def self.climber_profile_payload(climber_profile)
        climber_profile.attributes.slice(
          "height_inches",
          "wingspan_inches",
          "weight_lbs",
          "years_climbing",
          "training_age_years",
          "current_max_boulder_grade",
          "current_max_sport_grade",
          "comfortable_boulder_grade",
          "comfortable_sport_grade",
          "preferred_disciplines",
          "available_equipment",
          "weekly_training_days",
          "session_duration_minutes",
          "goals_short_term",
          "goals_long_term",
          "injuries",
          "style_strengths",
          "style_weaknesses",
          "additional_context"
        )
      end
      # Public: used by TrainingBlockGenerator too

      def self.training_block_payload(training_block)
        return nil if training_block.nil?

        training_block.attributes.slice(
          "name",
          "focus",
          "weeks_planned",
          "week_number",
          "started_at",
          "ends_at",
          "status",
          "ai_reasoning"
        )
      end
      private_class_method :training_block_payload

      def self.session_logs_payload(session_logs)
        session_logs.map do |log|
          log.attributes.slice(
            "date",
            "session_type",
            "duration_minutes",
            "perceived_exertion",
            "energy_level",
            "skin_condition",
            "finger_soreness",
            "general_soreness",
            "mood",
            "notes",
            "raw_input",
            "structured_data",
            "climbs_logged",
            "exercises_logged"
          )
        end
      end
      private_class_method :session_logs_payload

      def self.recent_session_logs(climber_profile)
        climber_profile.session_logs.order(date: :asc)
      end
      private_class_method :recent_session_logs

      def self.previous_blocks_payload(climber_profile)
        climber_profile.training_blocks.where(status: [ :completed, :abandoned ]).order(started_at: :asc).map do |block|
          {
            name: block.name,
            focus: block.focus,
            weeks_planned: block.weeks_planned,
            started_at: block.started_at,
            ends_at: block.ends_at,
            status: block.status,
            overall_focus: block.overall_focus,
            weekly_summaries: block.weekly_plans.order(:week_number).map { |wp|
              { week_number: wp.week_number, week_focus: wp.week_focus, summary: wp.summary }
            }
          }
        end
      end
      private_class_method :previous_blocks_payload

      def self.benchmarks_payload(climber_profile)
        climber_profile.climbing_benchmarks.includes(:climbing_benchmark_histories).map do |bm|
          {
            key: bm.benchmark_key,
            label: bm.label,
            current_value: bm.value,
            unit: bm.definition&.dig(:unit),
            category: bm.definition&.dig(:category),
            history: bm.climbing_benchmark_histories.order(:recorded_at).map { |h|
              { value: h.value, recorded_at: h.recorded_at }
            }
          }
        end
      end
      private_class_method :benchmarks_payload

      ACTIVITY_TO_SESSION_TYPE = {
        "bouldering" => "climbing",
        "rope_climbing" => "climbing",
        "board_climbing" => "board",
        "hangboarding" => "hangboard",
        "strength_training" => "strength",
        "cardio" => "cardio",
        "mobility" => "mobility"
      }.freeze

      def self.map_activities_to_session_types(activities)
        activities.map { |a| ACTIVITY_TO_SESSION_TYPE[a] }.compact.uniq
      end
      private_class_method :map_activities_to_session_types
    end
  end
end
