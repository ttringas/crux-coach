# frozen_string_literal: true

require "json"

module Ai
  class TrainingBlockGenerator
    def self.call(climber_profile:, start_date:, end_date:, weeks_planned:, comments: "", training_days: [], activities: [])
      raise ArgumentError, "Training blocks cannot exceed 12 weeks" if weeks_planned > 12

      prompts = build_prompts(climber_profile, start_date, end_date, weeks_planned, comments, training_days: training_days, activities: activities)

      response = Ai::Client.generate(
        prompt: prompts[:user],
        system: prompts[:system],
        user: climber_profile.user,
        interaction_type: :plan_generation,
        max_tokens: 64000
      )

      parsed = parse_json_response(response.content)
      create_training_block!(climber_profile, parsed, start_date, end_date, weeks_planned)
    end

    def self.regenerate_future!(training_block:, comments: "")
      climber_profile = training_block.climber_profile
      today = Date.current

      # Remove future weekly plans and their sessions
      training_block.weekly_plans.each do |wp|
        if wp.week_of > today
          wp.destroy!
        elsif wp.week_of <= today && (wp.week_of + 6) >= today
          # Current week: keep past sessions, remove future ones
          wp.planned_sessions.where(status: :todo).each do |ps|
            session_date = wp.week_of + ps.day_of_week
            ps.destroy! if session_date > today
          end
        end
      end

      # Calculate remaining weeks
      remaining_start = (today + 1).beginning_of_week(:monday)
      remaining_start = today.beginning_of_week(:monday) + 7 if remaining_start <= today
      remaining_weeks = ((training_block.ends_at - remaining_start).to_i / 7.0).ceil
      remaining_weeks = [ remaining_weeks, 1 ].max

      prompts = build_regeneration_prompts(climber_profile, training_block, remaining_start, remaining_weeks, comments)

      response = Ai::Client.generate(
        prompt: prompts[:user],
        system: prompts[:system],
        user: climber_profile.user,
        interaction_type: :plan_generation,
        max_tokens: 64000
      )

      parsed = parse_json_response(response.content)
      create_remaining_weeks!(training_block, parsed, remaining_start, remaining_weeks)
      training_block
    end

    private

    def self.build_prompts(climber_profile, start_date, end_date, weeks_planned, comments, training_days: [], activities: [])
      profile_data = Ai::Prompts::PlanGenerator.climber_profile_payload(climber_profile)
      session_logs = all_session_logs(climber_profile)

      {
        system: system_prompt,
        user: <<~TEXT
          Generate a complete training block plan for a climber.

          CLIMBER PROFILE:
          #{JSON.pretty_generate(profile_data)}

          PREVIOUS TRAINING BLOCKS:
          #{JSON.pretty_generate(previous_blocks_payload(climber_profile))}

          BENCHMARKS & PROGRESSION:
          #{JSON.pretty_generate(benchmarks_payload(climber_profile))}

          ALL SESSION LOGS:
          #{JSON.pretty_generate(session_logs.map { |l| session_log_payload(l) })}

          TRAINING BLOCK DETAILS:
          - Start date: #{start_date}
          - End date: #{end_date}
          - Total weeks: #{weeks_planned}
          - User comments/goals: #{comments.presence || "None provided"}
          #{training_days_prompt(training_days)}
          #{activities_prompt(activities)}

          INSTRUCTIONS:
          Generate a JSON object with this structure:
          {
            "name": "Block name (e.g. 'Power Endurance Phase')",
            "focus": "power|power_endurance|endurance|technique|base|deload|project",
            "overall_focus": "2-3 sentence description of the overall training focus and goals for this block",
            "ai_reasoning": "Why this block structure was chosen",
            "weeks": [
              {
                "week_number": 1,
                "week_focus": "High-level focus for this week (e.g. 'Volume Base Building')",
                "summary": "Brief description of the week's goals",
                "detailed": true,
                "sessions": [
                  {
                    "day_of_week": 0,
                    "session_type": "climbing|board|hangboard|strength|cardio|mobility|rest|outdoor",
                    "title": "Session title",
                    "description": "Detailed description of the session",
                    "estimated_duration_minutes": 90,
                    "intensity": "low|moderate|high|max",
                    "exercises": []
                  }
                ]
              }
            ]
          }

          IMPORTANT RULES:
          - Generate ALL weeks with FULL detail: every session must have a complete description, specific exercises with sets/reps/rest, and clear coaching cues
          - Include rest days where appropriate
          - day_of_week: 0=Monday, 1=Tuesday, ... 6=Sunday
          - Return ONLY valid JSON, no markdown
          #{training_days_rules(training_days)}
          #{activities_rules(activities)}
        TEXT
      }
    end
    private_class_method :build_prompts

    def self.build_regeneration_prompts(climber_profile, training_block, remaining_start, remaining_weeks, comments)
      profile_data = Ai::Prompts::PlanGenerator.climber_profile_payload(climber_profile)

      # Gather completed session history from this block
      completed_sessions = training_block.weekly_plans.flat_map do |wp|
        wp.planned_sessions.where(status: :completed).map do |ps|
          { date: (wp.week_of + ps.day_of_week).to_s, title: ps.title, type: ps.session_type, intensity: ps.intensity }
        end
      end

      {
        system: system_prompt,
        user: <<~TEXT
          Regenerate the REMAINING weeks of an existing training block.

          CLIMBER PROFILE:
          #{JSON.pretty_generate(profile_data)}

          EXISTING BLOCK:
          - Name: #{training_block.name}
          - Focus: #{training_block.focus}
          - Original end date: #{training_block.ends_at}
          - Overall focus: #{training_block.overall_focus}

          PREVIOUS TRAINING BLOCKS:
          #{JSON.pretty_generate(previous_blocks_payload(climber_profile))}

          BENCHMARKS & PROGRESSION:
          #{JSON.pretty_generate(benchmarks_payload(climber_profile))}

          ALL SESSION LOGS:
          #{JSON.pretty_generate(all_session_logs(climber_profile).map { |l| session_log_payload(l) })}

          COMPLETED SESSIONS IN CURRENT BLOCK:
          #{JSON.pretty_generate(completed_sessions)}

          USER FEEDBACK/COMMENTS:
          #{comments.presence || "None"}

          REGENERATION DETAILS:
          - Start regenerating from: #{remaining_start}
          - Remaining weeks: #{remaining_weeks}

          Generate JSON with same structure as initial generation. ALL weeks must be fully detailed with complete descriptions, specific exercises, sets/reps/rest for every session.
          Return ONLY valid JSON.

          {
            "weeks": [
              {
                "week_number": 1,
                "week_focus": "...",
                "summary": "...",
                "detailed": true,
                "sessions": [...]
              }
            ]
          }
        TEXT
      }
    end
    private_class_method :build_regeneration_prompts

    DAY_INDICES = { "Monday" => 0, "Tuesday" => 1, "Wednesday" => 2, "Thursday" => 3, "Friday" => 4, "Saturday" => 5, "Sunday" => 6 }.freeze

    def self.training_days_prompt(training_days)
      return "" if training_days.blank?
      rest_days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday] - training_days
      "- Selected training days: #{training_days.join(', ')}\n          - Rest days (DO NOT schedule training): #{rest_days.join(', ')}"
    end
    private_class_method :training_days_prompt

    def self.activities_prompt(activities)
      return "" if activities.blank?
      all_activities = [ "Bouldering", "Rope climbing", "Board climbing", "Hangboarding", "Strength training", "Cardio", "Mobility" ]
      excluded = all_activities - activities
      result = "- Selected activities: #{activities.join(', ')}"
      result += "\n          - EXCLUDED activities (DO NOT include): #{excluded.join(', ')}" if excluded.any?
      result
    end
    private_class_method :activities_prompt

    def self.training_days_rules(training_days)
      return "" if training_days.blank?
      indices = training_days.map { |d| DAY_INDICES[d] }.compact
      rest_indices = (0..6).to_a - indices
      <<~RULES.strip
        - STRICT TRAINING DAYS CONSTRAINT: You MUST ONLY schedule training sessions on these day indices: #{indices.join(', ')} (#{training_days.join(', ')}). All other days (indices #{rest_indices.join(', ')}) MUST be rest days. Do NOT place any training on non-selected days.
      RULES
    end
    private_class_method :training_days_rules

    def self.activities_rules(activities)
      return "" if activities.blank?
      <<~RULES.strip
        - STRICT ACTIVITY CONSTRAINT: You MUST ONLY include sessions from these activity types: #{activities.join(', ')}. Do NOT include any session types outside this list. Map activities to session_type as follows: Bouldering→climbing, Rope climbing→climbing, Board climbing→board, Hangboarding→hangboard, Strength training→strength, Cardio→cardio, Mobility→mobility. Only use session_types that correspond to the selected activities.
      RULES
    end
    private_class_method :activities_rules

    def self.system_prompt
      <<~TEXT
        You are an expert climbing coach and sport scientist. You design multi-week training blocks with proper periodization.
        - Balance volume and intensity across the block
        - Progressive overload with planned recovery/deload weeks
        - Finger load management: avoid back-to-back high finger intensity
        - Include climbing, strength, hangboard, mobility, and rest days
        - Honor injuries and constraints
        - Be specific and detailed for every week — include full exercise prescriptions with sets, reps, and rest periods
        Output must be valid JSON only. No markdown.
      TEXT
    end
    private_class_method :system_prompt

    def self.create_training_block!(climber_profile, parsed, start_date, end_date, weeks_planned)
      # Deactivate any current blocks
      climber_profile.training_blocks.current.update_all(status: :completed)

      ActiveRecord::Base.transaction do
        block = climber_profile.training_blocks.create!(
          name: parsed["name"] || "Training Block",
          focus: normalize_focus(parsed["focus"]),
          weeks_planned: weeks_planned,
          week_number: 1,
          started_at: start_date,
          ends_at: end_date,
          status: :active,
          ai_reasoning: parsed["ai_reasoning"].to_s,
          overall_focus: parsed["overall_focus"].to_s
        )

        Array(parsed["weeks"]).each_with_index do |week_data, index|
          week_of = start_date + (index * 7)
          week_of = week_of.beginning_of_week(:monday)

          wp = climber_profile.weekly_plans.create!(
            training_block: block,
            week_number: index + 1,
            week_of: week_of,
            status: index == 0 ? :active : :draft,
            ai_generated_plan: week_data,
            summary: week_data["summary"].to_s,
            week_focus: week_data["week_focus"].to_s
          )

          Array(week_data["sessions"]).each_with_index do |session, pos|
            wp.planned_sessions.create!(
              day_of_week: normalize_day_of_week(session["day_of_week"]),
              session_type: normalize_session_type(session["session_type"]),
              title: session["title"].to_s.presence || "Training Session",
              description: session["description"].to_s,
              estimated_duration_minutes: session["estimated_duration_minutes"],
              intensity: normalize_intensity(session["intensity"]),
              exercises: session["exercises"] || [],
              position: pos
            )
          end
        end

        block
      end
    end
    private_class_method :create_training_block!

    def self.create_remaining_weeks!(training_block, parsed, remaining_start, remaining_weeks)
      climber_profile = training_block.climber_profile
      existing_max_week = training_block.weekly_plans.maximum(:week_number) || 0

      ActiveRecord::Base.transaction do
        Array(parsed["weeks"]).each_with_index do |week_data, index|
          week_of = remaining_start + (index * 7)

          wp = climber_profile.weekly_plans.create!(
            training_block: training_block,
            week_number: existing_max_week + index + 1,
            week_of: week_of,
            status: :draft,
            ai_generated_plan: week_data,
            summary: week_data["summary"].to_s,
            week_focus: week_data["week_focus"].to_s
          )

          Array(week_data["sessions"]).each_with_index do |session, pos|
            wp.planned_sessions.create!(
              day_of_week: normalize_day_of_week(session["day_of_week"]),
              session_type: normalize_session_type(session["session_type"]),
              title: session["title"].to_s.presence || "Training Session",
              description: session["description"].to_s,
              estimated_duration_minutes: session["estimated_duration_minutes"],
              intensity: normalize_intensity(session["intensity"]),
              exercises: session["exercises"] || [],
              position: pos
            )
          end
        end
      end
    end
    private_class_method :create_remaining_weeks!

    def self.all_session_logs(climber_profile)
      climber_profile.session_logs.order(date: :asc)
    end
    private_class_method :all_session_logs

    def self.session_log_payload(log)
      log.attributes.slice(
        "date", "session_type", "duration_minutes", "perceived_exertion",
        "energy_level", "skin_condition", "finger_soreness", "general_soreness",
        "mood", "notes", "climbs_logged", "exercises_logged"
      )
    end
    private_class_method :session_log_payload

    def self.previous_blocks_payload(climber_profile)
      climber_profile.training_blocks.where(status: [ :completed, :abandoned ]).order(started_at: :asc).map do |block|
        {
          name: block.name,
          focus: block.focus,
          weeks_planned: block.weeks_planned,
          started_at: block.started_at,
          ends_at: block.ends_at,
          status: block.status,
          ai_reasoning: block.ai_reasoning,
          overall_focus: block.overall_focus,
          weekly_summaries: block.weekly_plans.order(:week_number).map { |wp|
            {
              week_number: wp.week_number,
              week_focus: wp.week_focus,
              summary: wp.summary
            }
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

    def self.parse_json_response(text)
      JSON.parse(text)
    rescue JSON::ParserError
      start_index = text.index("{")
      end_index = text.rindex("}")
      raise Ai::Client::Error, "AI response was not valid JSON" if start_index.nil? || end_index.nil?
      JSON.parse(text[start_index..end_index])
    end
    private_class_method :parse_json_response

    def self.normalize_focus(value)
      normalized = value.to_s.downcase.gsub(/\s+/, "_")
      return normalized if TrainingBlock.defined_enums["focus"].key?(normalized)
      "base"
    end
    private_class_method :normalize_focus

    def self.normalize_day_of_week(value)
      day = value.to_i
      day.clamp(0, 6)
    end
    private_class_method :normalize_day_of_week

    def self.normalize_session_type(value)
      normalized = value.to_s.downcase
      return normalized if PlannedSession.session_types.key?(normalized)
      "climbing"
    end
    private_class_method :normalize_session_type

    def self.normalize_intensity(value)
      normalized = value.to_s.downcase
      normalized = "max_effort" if normalized == "max"
      return normalized if PlannedSession.intensities.key?(normalized)
      "moderate"
    end
    private_class_method :normalize_intensity
  end
end
