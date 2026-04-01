class CalendarController < ApplicationController
  before_action :set_profile

  def show
    @view = params[:view].presence || "weekly"
    @training_block = @profile.training_blocks.current.first ||
                      @profile.training_blocks.order(created_at: :desc).first

    if @view == "monthly"
      setup_monthly_view
    else
      setup_weekly_view
    end
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def setup_weekly_view
    if params[:week_of].present?
      @selected_week_of = Date.parse(params[:week_of]).beginning_of_week(:monday)
    else
      @weekly_plan = @profile.weekly_plans.current.first || @profile.weekly_plans.order(week_of: :desc).first
      @selected_week_of = @weekly_plan&.week_of || Date.current.beginning_of_week(:monday)
    end

    @weekly_plan ||= @profile.weekly_plans.find_by(week_of: @selected_week_of)
    @week_dates = (@selected_week_of..(@selected_week_of + 6)).to_a
    @planned_sessions = @weekly_plan ? @weekly_plan.planned_sessions.order(:day_of_week, :position, :created_at).group_by(&:day_of_week) : {}
  end

  def setup_monthly_view
    if params[:month].present?
      @month_start = Date.parse(params[:month] + "-01").beginning_of_month
    else
      @month_start = Date.current.beginning_of_month
    end
    @month_end = @month_start.end_of_month

    # Get calendar grid dates (start from Monday of the first week)
    @calendar_start = @month_start.beginning_of_week(:monday)
    @calendar_end = @month_end.end_of_week(:monday)
    @calendar_dates = (@calendar_start..@calendar_end).to_a

    # Load all sessions in the range
    @weekly_plans = @profile.weekly_plans
      .includes(:planned_sessions)
      .where(week_of: (@calendar_start - 7)..@calendar_end)
      .order(:week_of)

    # Build a date => sessions hash
    @sessions_by_date = {}
    @weekly_plans.each do |wp|
      wp.planned_sessions.each do |ps|
        date = wp.week_of + ps.day_of_week
        @sessions_by_date[date] ||= []
        @sessions_by_date[date] << ps
      end
    end
  end
end
