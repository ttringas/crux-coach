module WeeklyPlansHelper
  def completed_exercises_count(session)
    return 0 if session.exercises.blank?

    completed_indices = Array(session.exercise_logs).filter_map do |log|
      next unless log.is_a?(Hash)
      next unless log["completed"]

      if log["exercise_index"].present?
        log["exercise_index"].to_i
      elsif log["set_key"].present?
        log["set_key"].to_s.split("_").first.to_i
      end
    end

    completed_indices.uniq.count
  end
end
