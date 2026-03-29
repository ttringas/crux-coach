class PlannedSessionsController < ApplicationController
  before_action :set_profile
  before_action :set_weekly_plan
  before_action :set_planned_session

  def show
    @immersive_layout = true
  end

  def update
    status_before = @planned_session.status
    @planned_session.assign_attributes(planned_session_params)

    if params.dig(:planned_session, :status).present?
      apply_status_transition
    end

    if @planned_session.save
      if @planned_session.completed? && (status_before != "completed" || @planned_session.session_log.nil?)
        @planned_session.ensure_session_log!
      end

      respond_to do |format|
        format.json do
          render json: {
            status: @planned_session.status,
            started_at: @planned_session.started_at&.iso8601,
            completed_at: @planned_session.completed_at&.iso8601
          }
        end
        format.turbo_stream { head :ok }
        format.html { redirect_to weekly_plan_planned_session_path(@weekly_plan, @planned_session) }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @planned_session.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream { render status: :unprocessable_entity }
        format.html { redirect_to weekly_plan_planned_session_path(@weekly_plan, @planned_session), alert: @planned_session.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def set_weekly_plan
    @weekly_plan = @profile.weekly_plans.find(params[:weekly_plan_id])
  end

  def set_planned_session
    @planned_session = @weekly_plan.planned_sessions.find(params[:id])
  end

  def planned_session_params
    params.fetch(:planned_session, {}).permit(
      :status,
      :session_notes,
      :perceived_exertion,
      :energy_level,
      :finger_soreness,
      :general_soreness,
      exercise_logs: [
        :exercise_index,
        :completed,
        :actual_sets,
        :actual_reps,
        :actual_weight,
        :actual_duration,
        :notes,
        :timer_seconds
      ]
    )
  end

  def apply_status_transition
    case @planned_session.status
    when "in_progress"
      @planned_session.started_at ||= Time.zone.now
    when "completed"
      @planned_session.started_at ||= Time.zone.now
      @planned_session.completed_at ||= Time.zone.now
    when "skipped"
      @planned_session.completed_at ||= Time.zone.now
    end
  end
end
