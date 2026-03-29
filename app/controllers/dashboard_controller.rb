class DashboardController < ApplicationController
  def show
    profile = current_climber_profile
    @current_plan = profile.weekly_plans.order(week_of: :desc).first
    @training_block = profile.training_blocks.order(created_at: :desc).first
    @recent_sessions = profile.session_logs.recent.limit(5)

    @today = Date.current
    now = Time.zone.now
    @greeting = case now.hour
      when 5..11 then "Good morning"
      when 12..17 then "Good afternoon"
      else "Good evening"
    end

    # Map Ruby wday (0=Sun) to plan day_of_week (0=Mon)
    plan_day = (@today.wday + 6) % 7
    @today_session = if @current_plan
      @current_plan.planned_sessions.find_by(day_of_week: plan_day)
    end

    # Build full week calendar with sessions
    @week_start = @today.beginning_of_week(:monday)
    @week_dates = (@week_start..(@week_start + 6)).to_a
    @planned_sessions_by_day = if @current_plan
      @current_plan.planned_sessions.index_by(&:day_of_week)
    else
      {}
    end
  end
end
