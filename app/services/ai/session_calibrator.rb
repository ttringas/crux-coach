# frozen_string_literal: true

require "json"

module Ai
  class SessionCalibrator
    HISTORY_WINDOW = 3

    def self.call(planned_session:, feedback:)
      profile = planned_session.weekly_plan.climber_profile

      prompts = build_prompts(planned_session: planned_session, profile: profile, feedback: feedback)

      response = Ai::Client.generate(
        prompt: prompts[:user],
        system: prompts[:system],
        user: profile.user,
        interaction_type: :session_calibration,
        max_tokens: 8000
      )

      parsed = parse_json_response(response.content)
      validate_parsed_response!(parsed)
      {
        exercises: normalize_exercises(parsed["exercises"]),
        reasoning: parsed["reasoning"].to_s,
        title: parsed["title"].presence,
        description: parsed["description"].presence,
        intensity: parsed["intensity"].presence,
        estimated_duration_minutes: parsed["estimated_duration_minutes"]
      }
    end

    def self.build_prompts(planned_session:, profile:, feedback:)
      training_block = planned_session.weekly_plan.training_block

      {
        system: system_prompt,
        user: <<~TEXT
          A climber is about to start today's training session and has provided feedback that the session may need
          adjustment. Calibrate ONLY today's session — do not change any other day in the plan.

          CLIMBER PROFILE:
          #{JSON.pretty_generate(profile_payload(profile))}

          ACTIVE TRAINING BLOCK (high-level overview only):
          #{JSON.pretty_generate(training_block_overview(training_block))}

          RECENT WEEK SUMMARIES (last 3):
          #{JSON.pretty_generate(recent_week_summaries(training_block))}

          NEXT 3 PLANNED SESSIONS (for context — do NOT modify these):
          #{JSON.pretty_generate(upcoming_sessions_payload(planned_session))}

          LAST 3 COMPLETED SESSIONS (with logged exercises, sets, reps, weight, RPE):
          #{JSON.pretty_generate(recent_completed_sessions_payload(profile))}

          TODAY'S SESSION (THE ONLY ONE YOU WILL MODIFY):
          #{JSON.pretty_generate(today_session_payload(planned_session))}

          ATHLETE'S CURRENT STATE FOR TODAY:
          - Energy level (1=low, 5=high): #{planned_session.energy_level || "not provided"}
          - Finger soreness (1=none, 5=very sore): #{planned_session.finger_soreness || "not provided"}
          - General soreness (1=none, 5=very sore): #{planned_session.general_soreness || "not provided"}

          ATHLETE'S FREE-FORM FEEDBACK:
          #{feedback.to_s.strip.presence || "(no additional comments)"}

          INSTRUCTIONS:
          - Start by identifying the underlying training goals of TODAY'S SESSION above (energy system, movement patterns, role in periodization). State those goals to yourself before deciding on any changes.
          - Make the SMALLEST set of adjustments needed to address the athlete's feedback while still hitting those underlying goals. This is a calibration, not a redesign.
          - Default to KEEPING the original exercises. Only modify exercises that genuinely conflict with the athlete's feedback. Pass through unchanged exercises as-is in your output.
          - When you must change something, prefer scaling (less volume, lighter load, easier grade) over substitution. Substitute only when scaling can't safely deliver the original stimulus.
          - If you do substitute, pick the closest functional analogue that targets the same quality (e.g. swap limit bouldering for skill bouldering, not for cardio).
          - Keep the session's structure, order, and overall focus intact unless the feedback makes that impossible. If you must change the session's focus entirely, explicitly justify it in "reasoning".
          - DO NOT propose changes that affect other days. Only this single session.
          - In "reasoning", explicitly state: (a) what you understood the session's original goals to be, (b) what you kept unchanged, (c) what you adjusted and why.
          - Output strict JSON with this exact shape:

          {
            "title": "Updated session title (string, optional — only set if changed)",
            "description": "Brief description of the calibrated session (string, optional)",
            "intensity": "low|moderate|high|max_effort (optional — only set if changed)",
            "estimated_duration_minutes": 60,
            "reasoning": "2-4 sentence explanation, written directly to the athlete in second person, of WHY you adjusted the session this way given their feedback. This is the most important field — be specific.",
            "exercises": [
              {
                "name": "Exercise name (required)",
                "category": "climbing|hangboard|board|strength|mobility|cardio (optional)",
                "sets": "3 (string or number, optional)",
                "target_reps": "8 (string or number, optional)",
                "rep_unit": "reps|seconds|minutes|problems|routes|attempts (optional, default 'reps')",
                "target_weight": "25 lbs (optional)",
                "target_grade": "V3 (optional)",
                "duration": "45 sec (optional)",
                "rest": "2 min (optional)",
                "description": "Cueing or technique notes (optional)",
                "notes": "Why this swap or scale was chosen (optional)"
              }
            ]
          }

          Return ONLY valid JSON — no markdown, no commentary outside of the JSON object.
        TEXT
      }
    end

    def self.system_prompt
      <<~TEXT
        You are an expert professional climbing coach with deep experience in sport science, periodization,
        injury management, and on-the-fly training calibration. An athlete is about to start a session you
        previously prescribed, and they're giving you live feedback (soreness ratings, energy, and free-form
        comments about how they feel, minor injuries, or equipment constraints).

        YOUR ROLE IS TO ADJUST, NOT REWRITE.

        You are NOT designing a new session from scratch. The session that's already prescribed exists for a
        specific reason — it fits a particular slot in the training block, targets specific physical qualities,
        and was chosen with the athlete's goals and history in mind. Your job is to make the SMALLEST possible
        adjustments needed to accommodate the athlete's current state while preserving the original training
        intent of the day.

        Your process MUST be:
          1. First, read TODAY'S SESSION carefully and identify its underlying goals: What energy system is it
             training? What movement patterns? What is its place in the weekly/block periodization?
          2. Identify which specific exercises (if any) actually conflict with the athlete's feedback. Exercises
             that don't conflict should be left exactly as they are.
          3. For exercises that DO conflict, make targeted modifications — scale intensity/volume, swap to a
             close substitute that trains the same quality, or remove only if no safe variant exists.
          4. The output should still clearly be "the same session, adjusted" — not a different workout.

        Hard constraints:
        - Do NOT change the session's overall training stimulus or focus unless the athlete's feedback makes
          it impossible to safely train that stimulus today. If you must, explain it explicitly in "reasoning".
        - Default to keeping the original exercises. Only modify or replace what conflicts with the feedback.
        - Keep the structure and order of the session intact when possible.
        - If the athlete's feedback is mild or vague, prefer small reductions (one less set, lighter weight,
          easier grade) over wholesale exercise swaps.
        - Do NOT modify other days. Only this single session.
        - Output must be safe, specific, and actionable with concrete sets/reps/weights/durations.

        Coaching principles you must follow:
        - High finger soreness (≥4) → no max-intensity hangboard, board, or limit bouldering. Substitute lower-intensity volume or technique work that trains the same broad quality.
        - High general soreness (≥4) or low energy (≤2) → reduce volume and intensity, prioritize movement quality and recovery — but keep the day's focus.
        - Reported injury → exclude or substitute only the exercises that load the affected area. Leave everything else untouched.
        - Missing equipment → find functional substitutes that target the same quality. Do not invent new training goals.
        - Always prescribe specific numbers (sets, reps, weight, duration, rest). Do not return vague exercises.
        - For every exercise you modify or replace, briefly explain WHY in that exercise's notes field. For exercises you keep unchanged, leave notes blank.
        - Summarize the overall calibration in the top-level "reasoning" field, written to the athlete in second person, explicitly stating what you kept the same and what you changed and why.

        Output must be valid JSON only — no markdown fences, no prose outside the JSON object.
      TEXT
    end

    def self.profile_payload(profile)
      profile.attributes.slice(
        "height_inches", "wingspan_inches", "weight_lbs", "years_climbing",
        "current_max_boulder_grade", "current_max_sport_grade",
        "comfortable_boulder_grade", "comfortable_sport_grade",
        "preferred_disciplines", "available_equipment",
        "weekly_training_days", "session_duration_minutes",
        "goals_short_term", "goals_long_term", "injuries",
        "style_strengths", "style_weaknesses", "additional_context"
      )
    end

    def self.training_block_overview(training_block)
      return {} unless training_block

      {
        name: training_block.name,
        focus: training_block.focus,
        overall_focus: training_block.overall_focus,
        weeks_planned: training_block.weeks_planned,
        started_at: training_block.started_at,
        ends_at: training_block.ends_at
      }
    end

    def self.recent_week_summaries(training_block)
      return [] unless training_block

      training_block.weekly_plans.order(week_number: :asc).last(HISTORY_WINDOW).map do |wp|
        {
          week_number: wp.week_number,
          week_of: wp.week_of,
          week_focus: wp.week_focus,
          summary: wp.summary
        }
      end
    end

    def self.today_session_payload(planned_session)
      {
        title: planned_session.title,
        session_type: planned_session.session_type,
        intensity: planned_session.intensity,
        estimated_duration_minutes: planned_session.estimated_duration_minutes,
        description: planned_session.description,
        exercises: planned_session.exercises
      }
    end

    def self.upcoming_sessions_payload(planned_session)
      profile = planned_session.weekly_plan.climber_profile
      session_date = planned_session.weekly_plan.week_of + planned_session.day_of_week
      upcoming = profile.weekly_plans
        .where("week_of >= ?", planned_session.weekly_plan.week_of)
        .order(:week_of)
        .flat_map { |wp| wp.planned_sessions.order(:day_of_week, :position).map { |ps| [ wp.week_of + ps.day_of_week, ps ] } }
        .select { |date, ps| date > session_date }
        .first(HISTORY_WINDOW)

      upcoming.map do |date, ps|
        {
          date: date.to_s,
          title: ps.title,
          session_type: ps.session_type,
          intensity: ps.intensity,
          estimated_duration_minutes: ps.estimated_duration_minutes,
          description: ps.description
        }
      end
    end

    def self.recent_completed_sessions_payload(profile)
      profile.session_logs.recent.limit(HISTORY_WINDOW).map do |log|
        {
          date: log.date,
          session_type: log.session_type,
          duration_minutes: log.duration_minutes,
          perceived_exertion: log.perceived_exertion,
          energy_level: log.energy_level,
          finger_soreness: log.finger_soreness,
          general_soreness: log.general_soreness,
          notes: log.notes,
          exercises_logged: log.exercises_logged
        }
      end
    end

    def self.parse_json_response(text)
      JSON.parse(text)
    rescue JSON::ParserError
      start_index = text.index("{")
      end_index = text.rindex("}")
      raise Ai::Client::Error, "Calibration response was not valid JSON" if start_index.nil? || end_index.nil?
      JSON.parse(text[start_index..end_index])
    end

    def self.validate_parsed_response!(parsed)
      raise Ai::Client::Error, "Calibration response is not a JSON object" unless parsed.is_a?(Hash)
      exercises = parsed["exercises"]
      raise Ai::Client::Error, "Calibration response missing 'exercises' array" unless exercises.is_a?(Array)
      raise Ai::Client::Error, "Calibration produced no exercises" if exercises.empty?

      exercises.each_with_index do |ex, i|
        raise Ai::Client::Error, "Exercise #{i + 1} missing name" unless ex.is_a?(Hash) && ex["name"].to_s.strip.present?
      end
    end

    def self.normalize_exercises(raw)
      Array(raw).filter_map do |exercise|
        next unless exercise.is_a?(Hash)
        name = exercise["name"].to_s.strip
        next if name.blank?

        {
          "id" => SecureRandom.uuid,
          "source" => "calibration",
          "category" => exercise["category"].presence,
          "name" => name,
          "sets" => exercise["sets"].presence,
          "target_reps" => exercise["target_reps"].presence,
          "rep_unit" => exercise["rep_unit"].presence || "reps",
          "target_weight" => exercise["target_weight"].presence,
          "target_grade" => exercise["target_grade"].presence,
          "duration" => exercise["duration"].presence,
          "rest" => exercise["rest"].presence,
          "description" => exercise["description"].presence,
          "notes" => exercise["notes"].presence
        }.compact
      end
    end
  end
end
