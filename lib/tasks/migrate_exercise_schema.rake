# frozen_string_literal: true

namespace :exercises do
  desc "Migrate exercise JSONB data from legacy 'reps' field to new schema (target_reps, rep_unit, target_grade, etc.)"
  task migrate_schema: :environment do
    V_GRADE_PATTERN = /\bV\d+(?:\s*[-–]\s*V?\d+)?\b/i
    TIME_PATTERN = /^(\d+(?:\.\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h)$/i
    PURE_NUMBER_PATTERN = /^\d+$/
    COMPLEX_REP_PATTERN = /^\d+(?:\s*[-–]\s*\d+)+$/  # e.g. "1-2-3-4-3-2-1"

    def parse_time_unit(unit_str)
      case unit_str.downcase
      when /^s/, "seconds", "second", "secs", "sec"
        "seconds"
      when /^m/, "minutes", "minute", "mins", "min"
        "minutes"
      when /^h/, "hours", "hour", "hrs", "hr"
        "minutes" # convert concept, but keep as minutes
      else
        "seconds"
      end
    end

    migrated = 0
    skipped = 0

    PlannedSession.find_each do |session|
      exercises = session.exercises
      next if exercises.blank?

      changed = false

      exercises.each do |exercise|
        # Skip if already migrated
        next if exercise["target_reps"].present? || exercise["rep_unit"].present? || exercise["target_grade"].present?

        reps_value = exercise["reps"].to_s.strip
        next if reps_value.blank?

        name = (exercise["name"] || exercise["title"] || "").downcase
        notes = (exercise["notes"] || "").to_s

        # Case 1: Contains V-grade pattern (V2, V2-V3, etc.)
        if reps_value.match?(V_GRADE_PATTERN)
          grade_match = reps_value.match(V_GRADE_PATTERN)[0]
          exercise["target_grade"] = grade_match

          # Check if there's also a number for reps
          remaining = reps_value.gsub(V_GRADE_PATTERN, "").strip
          if remaining.match?(PURE_NUMBER_PATTERN)
            exercise["target_reps"] = remaining
            exercise["rep_unit"] = "problems"
          elsif name.include?("attempt") || notes.downcase.include?("attempt")
            exercise["rep_unit"] = "attempts"
          else
            exercise["rep_unit"] = "problems"
          end
          changed = true

        # Case 2: Time-based (e.g. "7 seconds", "10 minutes", "8m")
        elsif (time_match = reps_value.match(TIME_PATTERN))
          exercise["target_reps"] = time_match[1]
          exercise["rep_unit"] = parse_time_unit(time_match[2])
          changed = true

        # Case 3: Pure number (e.g. "12", "8")
        elsif reps_value.match?(PURE_NUMBER_PATTERN)
          exercise["target_reps"] = reps_value
          exercise["rep_unit"] = "reps"
          changed = true

        # Case 4: Complex pattern like "1-2-3-4-3-2-1"
        elsif reps_value.match?(COMPLEX_REP_PATTERN)
          exercise["target_reps"] = reps_value
          exercise["rep_unit"] = "problems"
          changed = true

        # Case 5: Contains duration-like text embedded in other text
        elsif (embedded_time = reps_value.match(/(\d+(?:\.\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m)/i))
          exercise["target_reps"] = embedded_time[1]
          exercise["rep_unit"] = parse_time_unit(embedded_time[2])
          # Put remaining text into notes
          remaining = reps_value.gsub(embedded_time[0], "").strip
          if remaining.present?
            existing_notes = exercise["notes"].to_s
            exercise["notes"] = [ existing_notes, remaining ].reject(&:blank?).join(". ")
          end
          changed = true

        # Case 6: Fallback — keep as target_reps with generic unit
        else
          exercise["target_reps"] = reps_value
          exercise["rep_unit"] = "reps"
          changed = true
        end
      end

      if changed
        session.update_column(:exercises, exercises)
        migrated += 1
      else
        skipped += 1
      end
    end

    puts "Exercise schema migration complete: #{migrated} sessions migrated, #{skipped} skipped."
  end
end
