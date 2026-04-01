# frozen_string_literal: true

require "json"

module Ai
  class PlanGenerator
    def self.call(climber_profile:, training_days: nil, activities: nil)
      prompts = Ai::Prompts::PlanGenerator.build(
        climber_profile: climber_profile,
        training_days: training_days,
        activities: activities
      )

      response = Ai::Client.generate(
        prompt: prompts[:user],
        system: prompts[:system],
        user: climber_profile.user,
        interaction_type: :plan_generation,
        max_tokens: 16384
      )

      parsed = parse_json_response(response.content)
      parsed = enforce_constraints!(parsed, training_days, activities)
      create_weekly_plan!(climber_profile, parsed)
    end

    def self.create_weekly_plan!(climber_profile, parsed)
      training_block = climber_profile.training_blocks.current.first ||
        climber_profile.training_blocks.order(created_at: :desc).first

      raise Ai::Client::Error, "No training block available for plan generation" if training_block.nil?

      week_number = training_block.week_number || (training_block.weekly_plans.maximum(:week_number) || 0) + 1
      week_of = Date.current.beginning_of_week(:monday)

      ActiveRecord::Base.transaction do
        weekly_plan = climber_profile.weekly_plans.create!(
          training_block: training_block,
          week_number: week_number,
          week_of: week_of,
          status: :draft,
          ai_generated_plan: parsed,
          summary: parsed["summary"].to_s
        )

        Array(parsed["sessions"]).each do |session|
          weekly_plan.planned_sessions.create!(
            day_of_week: normalize_day_of_week(session["day_of_week"]),
            session_type: normalize_session_type(session["session_type"]),
            title: session["title"].to_s,
            description: session["description"].to_s,
            estimated_duration_minutes: session["estimated_duration_minutes"],
            intensity: normalize_intensity(session["intensity"]),
            exercises: session["exercises"] || []
          )
        end

        weekly_plan
      end
    end
    private_class_method :create_weekly_plan!

    def self.parse_json_response(text)
      JSON.parse(text)
    rescue JSON::ParserError
      extracted = extract_json(text)
      return JSON.parse(extracted) if extracted

      raise Ai::Client::Error, "AI response was not valid JSON"
    end
    private_class_method :parse_json_response

    def self.extract_json(text)
      return nil if text.blank?

      start_index = text.index("{")
      end_index = text.rindex("}")
      return nil if start_index.nil? || end_index.nil? || end_index <= start_index

      text[start_index..end_index]
    end
    private_class_method :extract_json

    def self.normalize_day_of_week(value)
      day = value.to_i
      day = 0 if day.negative?
      day = 6 if day > 6
      day
    end
    private_class_method :normalize_day_of_week

    def self.normalize_session_type(value)
      normalized = value.to_s.downcase
      return normalized if PlannedSession.session_types.key?(normalized)

      "climbing"
    end
    private_class_method :normalize_session_type

    def self.enforce_constraints!(parsed, training_days, activities)
      allowed_days = Array(training_days).presence&.map(&:to_i)
      allowed_types = if Array(activities).present?
        Ai::Prompts::PlanGenerator::ACTIVITY_TO_SESSION_TYPE
          .values_at(*Array(activities))
          .compact.uniq
      end

      return parsed unless allowed_days || allowed_types

      parsed["sessions"] = Array(parsed["sessions"]).select do |session|
        day = normalize_day_of_week(session["day_of_week"])
        stype = normalize_session_type(session["session_type"])

        day_ok = allowed_days.nil? || allowed_days.include?(day)
        type_ok = allowed_types.nil? || allowed_types.include?(stype) || stype == "rest"
        day_ok && type_ok
      end

      parsed
    end
    private_class_method :enforce_constraints!

    def self.normalize_intensity(value)
      normalized = value.to_s.downcase
      normalized = "max_effort" if normalized == "max"
      return normalized if PlannedSession.intensities.key?(normalized)

      "moderate"
    end
    private_class_method :normalize_intensity
  end
end
