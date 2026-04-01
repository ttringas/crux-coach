class WeeklyPlansController < ApplicationController
  before_action :set_profile

  def index
    @training_block = @profile.training_blocks.order(created_at: :desc).first
    if params[:week_of].present?
      @selected_week_of = selected_week_of
      @weekly_plan = plan_for_week(@selected_week_of)
    else
      @weekly_plan = plan_for_week(nil)
      @selected_week_of = @weekly_plan&.week_of || Date.current.beginning_of_week(:monday)
    end
    @week_dates = week_dates_for(@weekly_plan || @selected_week_of)
    @planned_sessions = sessions_by_day(@weekly_plan)
  end

  def show
    @weekly_plan = @profile.weekly_plans.find(params[:id])
    @training_block = @profile.training_blocks.order(created_at: :desc).first
    @selected_week_of = @weekly_plan.week_of
    @week_dates = week_dates_for(@weekly_plan)
    @planned_sessions = sessions_by_day(@weekly_plan)
  end

  def create
    weekly_plan = Ai::PlanGenerator.call(
      climber_profile: @profile,
      training_days: params[:training_days],
      activities: params[:activities]
    )
    redirect_to weekly_plans_path(week_of: weekly_plan.week_of), notice: "Next week plan generated."
  rescue Ai::Client::Error => e
    redirect_to weekly_plans_path, alert: e.message
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def week_dates_for(plan_or_date)
    week_of = plan_or_date.is_a?(Date) ? plan_or_date : plan_or_date&.week_of
    return [] unless week_of

    (week_of..(week_of + 6)).to_a
  end

  def selected_week_of
    return Date.current.beginning_of_week(:monday) unless params[:week_of].present?

    Date.parse(params[:week_of]).beginning_of_week(:monday)
  rescue ArgumentError
    Date.current.beginning_of_week(:monday)
  end

  def plan_for_week(week_of)
    return @profile.weekly_plans.current.first || @profile.weekly_plans.order(week_of: :desc).first if params[:week_of].blank?

    @profile.weekly_plans.find_by(week_of: week_of)
  end

  def sessions_by_day(plan)
    return {} unless plan

    plan.planned_sessions.order(:day_of_week, :position, :created_at).group_by(&:day_of_week)
  end
end
