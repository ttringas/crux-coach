# frozen_string_literal: true

require "json"

module Ai
  module Prompts
    class SessionParser
      def self.build(raw_text:, climber_profile:)
        {
          system: system_prompt,
          user: user_prompt(raw_text, climber_profile)
        }
      end

      def self.system_prompt
        <<~TEXT
          You are an expert climbing coach. Extract structured session data from natural language.
          Return valid JSON only. No markdown. If a field is unknown, use null.
        TEXT
      end

      def self.user_prompt(raw_text, climber_profile)
        payload = {
          climber_profile: climber_profile_payload(climber_profile),
          raw_text: raw_text,
          output_schema: {
            session_type: "climbing|board|hangboard|strength|cardio|mobility|rest|outdoor",
            duration_minutes: "integer",
            perceived_exertion: "1-10",
            climbs_logged: [
              {
                grade: "string",
                style: "string",
                attempts: "integer",
                sent: "boolean"
              }
            ],
            exercises_logged: [
              {
                name: "string",
                sets: "integer",
                reps: "integer or string",
                weight: "string",
                duration: "string"
              }
            ]
          }
        }

        <<~TEXT
          Parse the session description into the JSON schema below.

          #{JSON.pretty_generate(payload)}
        TEXT
      end

      def self.climber_profile_payload(climber_profile)
        climber_profile.attributes.slice(
          "preferred_disciplines",
          "available_equipment",
          "injuries",
          "goals_short_term",
          "goals_long_term"
        )
      end
      private_class_method :climber_profile_payload
    end
  end
end
