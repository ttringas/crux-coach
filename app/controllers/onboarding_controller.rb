class OnboardingController < ApplicationController
  before_action :set_profile
  before_action :set_step

  def show
  end

  def update
    update_user_name

    if @profile.update(profile_params)
      if @step == 6
        begin
          start_date = Date.current.beginning_of_week(:monday)
          weeks_planned = 4
          end_date = start_date + weeks_planned.weeks

          GenerateTrainingBlockJob.perform_later(
            climber_profile_id: @profile.id,
            start_date: start_date,
            end_date: end_date,
            weeks_planned: weeks_planned,
            comments: @profile.additional_context.to_s,
            training_days: [],
            activities: []
          )

          @profile.update!(
            training_block_generation_status: "pending",
            training_block_generation_error: nil,
            training_block_generation_training_block_id: nil
          )

          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: turbo_stream.replace(
                ActionView::RecordIdentifier.dom_id(@profile, :training_block_generation),
                partial: "training_blocks/generation_loading",
                locals: { profile: @profile }
              )
            end
            format.html { redirect_to dashboard_path, notice: "Plan generation started. We'll notify you when it's ready." }
          end
        rescue Ai::Client::Error => e
          flash.now[:alert] = e.message
          render :show, status: :unprocessable_entity
        end
      else
        redirect_to onboarding_path(@step + 1)
      end
    else
      render :show, status: :unprocessable_entity
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
      permitted[:injuries] = sanitized.reject do |injury|
        injury.values.all?(&:blank?)
      end
    end

    permitted
  end
end
