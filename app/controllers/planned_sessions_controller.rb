class PlannedSessionsController < ApplicationController
  before_action :set_profile
  before_action :set_weekly_plan
  before_action :set_planned_session

  def show
    @immersive_layout = true
    @exercise_library_matches = ExerciseLibrary::Matcher.new.match_exercises(@planned_session.exercises)
    @exercise_library_entries = ExerciseLibraryEntry.order(:name).select(:id, :name, :category, :description)
  end

  def update
    status_before = @planned_session.status
    @planned_session.assign_attributes(planned_session_params)

    if params.dig(:planned_session, :target_date).present?
      move_to_target_date(params[:planned_session][:target_date])
    end

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
            day_of_week: @planned_session.day_of_week,
            position: @planned_session.position,
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

  def update_exercises
    exercises = normalize_exercises(params[:exercises])
    @planned_session.exercises = exercises

    if @planned_session.save
      respond_to do |format|
        format.json { render json: { exercises: @planned_session.exercises } }
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
      :day_of_week,
      :position,
      :session_notes,
      :perceived_exertion,
      :energy_level,
      :finger_soreness,
      :general_soreness,
      exercise_logs: [
        :set_key,
        :exercise_index,
        :set_index,
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

  def move_to_target_date(target_date_str)
    target_date = Date.parse(target_date_str)
    target_week_of = target_date.beginning_of_week(:monday)

    return if @weekly_plan.week_of == target_week_of

    target_plan = @profile.weekly_plans.find_by(week_of: target_week_of)
    target_plan ||= @profile.weekly_plans.create!(
      week_of: target_week_of,
      training_block: @weekly_plan.training_block,
      status: :active
    )

    @planned_session.weekly_plan = target_plan
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

  def normalize_exercises(raw)
    Array(raw).filter_map do |exercise|
      next unless exercise.is_a?(Hash) || exercise.is_a?(ActionController::Parameters)

      data = exercise.is_a?(ActionController::Parameters) ? exercise.to_unsafe_h : exercise
      data = data.deep_stringify_keys
      name = data["name"].presence || data["title"].presence
      next unless name.present?

      {
        "id" => data["id"].presence || SecureRandom.uuid,
        "source" => data["source"].presence,
        "library_entry_id" => data["library_entry_id"].presence,
        "category" => data["category"].presence,
        "name" => name,
        "sets" => data["sets"].presence,
        "reps" => data["reps"].presence,
        "duration" => data["duration"].presence,
        "rest" => data["rest"].presence,
        "description" => data["description"].presence,
        "notes" => data["notes"].presence
      }.compact
    end
  end
end
