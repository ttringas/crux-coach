class OnboardingController < ApplicationController
  before_action :set_profile
  before_action :set_step

  def show
  end

  def update
    update_user_name

    if @profile.update(profile_params)
      if @step == 6
        @profile.update!(onboarding_completed: true)

        respond_to do |format|
          format.turbo_stream { redirect_to training_blocks_path, status: :see_other }
          format.html { redirect_to training_blocks_path }
        end
      else
        respond_to do |format|
          format.turbo_stream { redirect_to onboarding_path(@step + 1), status: :see_other }
          format.html { redirect_to onboarding_path(@step + 1) }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :show, status: :unprocessable_entity, formats: [ :html ] }
        format.html { render :show, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def set_step
    @step = params[:id].to_i
    @step = 1 if @step < 1
    @step = 6 if @step > 6
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
      :training_age_years,
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
      permitted[:injuries] = sanitized.reject do |injury|
        injury.values.all?(&:blank?)
      end
    end

    permitted
  end
end
