class DashboardController < ApplicationController
  def show
    profile = current_climber_profile
    @current_plan = profile.weekly_plans.current.first
    @training_block = profile.training_blocks.current.first
    @recent_sessions = profile.session_logs.recent.limit(5)

    @today = Date.current
    @today_session = if @current_plan
      @current_plan.planned_sessions.find_by(day_of_week: @today.wday)
    end

    @week_dates = (@today.beginning_of_week..@today.end_of_week).to_a
  end
end
