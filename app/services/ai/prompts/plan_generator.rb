# frozen_string_literal: true

require "json"

module Ai
  module Prompts
    class PlanGenerator
      def self.build(climber_profile:, training_block: nil, session_logs: nil)
        training_block ||= climber_profile.training_blocks.current.first
        session_logs ||= recent_session_logs(climber_profile)

        {
          system: system_prompt,
          user: user_prompt(climber_profile, training_block, session_logs)
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

          Output must be valid JSON only. No markdown. Follow the exact schema provided by the user prompt.
        TEXT
      end

      def self.user_prompt(climber_profile, training_block, session_logs)
        payload = {
          climber_profile: climber_profile_payload(climber_profile),
          training_block: training_block_payload(training_block),
          recent_session_logs: session_logs_payload(session_logs),
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
                      reps: "string or integer",
                      duration: "string",
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
          "training_age_months",
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
      private_class_method :climber_profile_payload

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
        climber_profile.session_logs
          .where(date: 4.weeks.ago.to_date..Date.current)
          .order(date: :asc)
      end
      private_class_method :recent_session_logs
    end
  end
end
