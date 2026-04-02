module CoachPortal
  class DashboardController < ApplicationController
    before_action :require_coach

    def show
      @coach = current_user.coach
      @athletes = @coach.climber_profiles.includes(:user)
    end

    private

    def require_coach
      return if current_user&.coach?

      redirect_to calendar_path, alert: "Access denied."
    end
  end
end
