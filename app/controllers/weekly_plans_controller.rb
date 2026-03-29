class WeeklyPlansController < ApplicationController
  before_action :set_profile

  def index
    @weekly_plan = @profile.weekly_plans.current.first || @profile.weekly_plans.order(week_of: :desc).first
    @week_dates = week_dates_for(@weekly_plan)
    @planned_sessions = sessions_by_day(@weekly_plan)
  end

  def show
    @weekly_plan = @profile.weekly_plans.find(params[:id])
    @week_dates = week_dates_for(@weekly_plan)
    @planned_sessions = sessions_by_day(@weekly_plan)

    if turbo_frame_request? && params[:session_id].present?
      session = @weekly_plan.planned_sessions.find(params[:session_id])
      render partial: "weekly_plans/session_details", locals: { session: session }
    end
  end

  def create
    weekly_plan = Ai::PlanGenerator.call(climber_profile: @profile)
    redirect_to weekly_plan_path(weekly_plan), notice: "Next week plan generated."
  rescue Ai::Client::Error => e
    redirect_to weekly_plans_path, alert: e.message
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def week_dates_for(plan)
    return [] unless plan&.week_of

    (plan.week_of..(plan.week_of + 6)).to_a
  end

  def sessions_by_day(plan)
    return {} unless plan

    plan.planned_sessions.group_by(&:day_of_week)
  end
end
