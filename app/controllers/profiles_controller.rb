class ProfilesController < ApplicationController
  before_action :set_profile

  def show
  end

  def edit
  end

  def update
    update_user_name

    if @profile.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def update_user_name
    return unless params[:user].is_a?(ActionController::Parameters)

    current_user.update(params.require(:user).permit(:name))
  end

  def profile_params
    permitted = params.fetch(:climber_profile, {}).permit(
      :height_inches,
      :wingspan_inches,
      :weight_lbs,
      :years_climbing,
      :training_age_months,
      :current_max_boulder_grade,
      :current_max_sport_grade,
      :comfortable_boulder_grade,
      :comfortable_sport_grade,
      :weekly_training_days,
      :session_duration_minutes,
      :goals_short_term,
      :goals_long_term,
      :additional_context,
      preferred_disciplines: [],
      available_equipment: [],
      style_strengths: [],
      style_weaknesses: [],
      injuries: %i[area severity notes date_started still_active]
    )

    if params.dig(:climber_profile, :injuries).is_a?(Array)
      sanitized = params[:climber_profile][:injuries].map do |injury|
        injury.slice("area", "severity", "notes", "date_started", "still_active")
      end
      permitted[:injuries] = sanitized.reject { |injury| injury.values.all?(&:blank?) }
    end

    permitted
  end
end
