# frozen_string_literal: true

namespace :exercises do
  desc "Re-migrate exercise schema with improved parsing"
  task remigrate: :environment do
    V_GRADE = /\bV\d+(?:\s*[-–]\s*V?\d+)?\b/i

    def parse_reps(reps_str, name, notes)
      raw = reps_str.to_s.strip
      return {} if raw.blank?

      result = {}
      name_lower = (name || "").downcase
      notes_lower = (notes || "").downcase

      # 1. V-grade pattern (V2, V2-V3, etc.)
      if raw.match?(V_GRADE)
        grade = raw.match(V_GRADE)[0]
        result["target_grade"] = grade
        remaining = raw.gsub(V_GRADE, "").strip.gsub(/^[-–,.\s]+|[-–,.\s]+$/, "")

        if remaining.match?(/^\d+$/)
          result["target_reps"] = remaining
        end

        if name_lower.include?("attempt") || notes_lower.include?("attempt")
          result["rep_unit"] = "attempts"
        elsif remaining.match?(/progression|pyramid|level|continuous/)
          result["rep_unit"] = "problems"
        else
          result["rep_unit"] = "problems"
        end

      # 2. Range + time unit: "30-45 seconds"
      elsif (m = raw.match(/^(\d+(?:\s*[-–]\s*\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m)\b/i))
        result["target_reps"] = m[1].gsub(/\s/, "")
        result["rep_unit"] = m[2].downcase.start_with?("s") ? "seconds" : "minutes"

      # 3. Number + unit word: "4 problems", "2 routes", "1 attempt", "3 touches"
      elsif (m = raw.match(/^(\d+(?:\s*[-–]\s*\d+)?)\s+(problems?|routes?|attempts?|touches?|exercises?|movements?\s+each)\s*$/i))
        result["target_reps"] = m[1].gsub(/\s/, "")
        unit_word = m[2].downcase.gsub(/s$/, "").strip
        case unit_word
        when "problem" then result["rep_unit"] = "problems"
        when "route" then result["rep_unit"] = "routes"
        when "attempt" then result["rep_unit"] = "attempts"
        when "touch", "touche" then result["rep_unit"] = "reps"
        when "exercise" then result["rep_unit"] = "reps"
        when /movement/ then result["rep_unit"] = "reps"
        else result["rep_unit"] = "reps"
        end

      # 4. Number + "each" / "each leg" / "each side"
      elsif (m = raw.match(/^(\d+(?:\s*[-–]\s*\d+)?)\s+each\b(.*)/i))
        result["target_reps"] = m[1].gsub(/\s/, "")
        result["rep_unit"] = "reps"
        qualifier = m[2].strip
        result["_append_notes"] = "each #{qualifier}".strip if qualifier.present?

      # 5. Pure time: "10 minutes", "7 seconds"
      elsif (m = raw.match(/^(\d+(?:\.\d+)?)\s*(seconds?|secs?|s|minutes?|mins?|m|hours?|hrs?|h)$/i))
        result["target_reps"] = m[1]
        result["rep_unit"] = m[2].downcase.start_with?("s") ? "seconds" : "minutes"

      # 6. Embedded time in text: "30s plank variations", "45s exercises"
      elsif (m = raw.match(/(\d+)\s*(s|sec|seconds?|m|min|minutes?)\b\s*(.*)/i))
        result["target_reps"] = m[1]
        result["rep_unit"] = m[2].downcase.start_with?("s") ? "seconds" : "minutes"
        remainder = m[3].strip
        result["_append_notes"] = remainder if remainder.present?

      # 7. Pure number
      elsif raw.match?(/^\d+$/)
        result["target_reps"] = raw
        result["rep_unit"] = "reps"

      # 8. Numeric range: "12-15", "3-5"
      elsif raw.match?(/^\d+\s*[-–]\s*\d+$/)
        result["target_reps"] = raw.gsub(/\s/, "")
        result["rep_unit"] = "reps"

      # 9. Complex pattern: "1-2-3-4-3-2-1"
      elsif raw.match?(/^\d+(?:\s*[-–]\s*\d+){2,}$/)
        result["target_reps"] = raw.gsub(/\s/, "")
        result["rep_unit"] = "problems"

      # 10. Mixed like "1 problem/route"
      elsif (m = raw.match(/^(\d+)\s+(\S+)/))
        result["target_reps"] = m[1]
        result["rep_unit"] = "reps"
        result["_append_notes"] = m[2] if m[2].present? && !m[2].match?(/^\d/)

      # 11. Fallback
      else
        result["target_reps"] = raw
        result["rep_unit"] = "reps"
      end

      result
    end

    migrated = 0

    PlannedSession.find_each do |session|
      exercises = session.exercises
      next if exercises.blank?

      changed = false
      exercises.each do |ex|
        reps_val = ex["reps"].to_s.strip
        next if reps_val.blank?

        # Clear previous migration attempts
        ex.delete("target_reps")
        ex.delete("rep_unit")
        ex.delete("target_grade")
        ex.delete("target_weight") unless ex.key?("weight")

        parsed = parse_reps(reps_val, ex["name"], ex["notes"])
        ex["target_reps"] = parsed["target_reps"] if parsed["target_reps"]
        ex["rep_unit"] = parsed["rep_unit"] if parsed["rep_unit"]
        ex["target_grade"] = parsed["target_grade"] if parsed["target_grade"]

        # Handle note appendage (but don't duplicate)
        if parsed["_append_notes"].present?
          existing = ex["notes"].to_s
          unless existing.include?(parsed["_append_notes"])
            ex["notes"] = [existing, parsed["_append_notes"]].reject(&:blank?).join(". ")
          end
        end

        # Clean up notes that got polluted by first migration
        if ex["notes"].present?
          # Remove "30-" style artifacts from bad first migration
          ex["notes"] = ex["notes"].gsub(/\. \d+[-–]$/, "").gsub(/^\d+[-–]\. /, "").strip
          ex["notes"] = ex["notes"].gsub(/\. $/, "").strip
        end

        changed = true
      end

      if changed
        session.update_column(:exercises, exercises)
        migrated += 1
      end
    end

    puts "Re-migration complete: #{migrated} sessions updated."
  end
end
