module CoachPortal
  class AthletesController < ApplicationController
    before_action :require_coach
    before_action :set_athlete

    def show
      @current_plan = @athlete.weekly_plans.current.first
      @recent_sessions = @athlete.session_logs.recent.limit(5)
    end

    def edit
      @current_plan = @athlete.weekly_plans.current.first
    end

    def update
      @current_plan = @athlete.weekly_plans.current.first
      if @current_plan&.update(weekly_plan_params)
        redirect_to coach_athlete_path(@athlete), notice: "Plan updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def require_coach
      return if current_user&.coach?

      redirect_to dashboard_path, alert: "Access denied."
    end

    def set_athlete
      @athlete = current_user.coach.climber_profiles.find(params[:id])
    end

    def weekly_plan_params
      params.fetch(:weekly_plan, {}).permit(:coach_notes, :summary, :status)
    end
  end
end
