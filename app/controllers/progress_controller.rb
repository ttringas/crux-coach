class ProgressController < ApplicationController
  def show
    profile = current_climber_profile
    @session_logs = profile.session_logs.recent

    @sessions_per_week = @session_logs.group_by { |log| log.date.beginning_of_week }
    @grade_history = @session_logs.map do |log|
      { date: log.date, grade: log.structured_data["max_grade"] }
    end

    @volume_trends = @session_logs.map do |log|
      { date: log.date, minutes: log.duration_minutes }
    end
  end
end
