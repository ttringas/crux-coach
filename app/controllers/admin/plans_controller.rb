# frozen_string_literal: true

module Admin
  class PlansController < Admin::BaseController
    def index
      @weekly_plans = WeeklyPlan.includes(:climber_profile, :training_block, :planned_sessions, climber_profile: :user)
                                .order(created_at: :desc)
    end

    def show
      @weekly_plan = WeeklyPlan.includes(:planned_sessions, :training_block, climber_profile: :user).find(params[:id])
      @climber = @weekly_plan.climber_profile
    end
  end
end
