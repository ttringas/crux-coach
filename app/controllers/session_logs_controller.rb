class SessionLogsController < ApplicationController
  before_action :set_profile

  def index
    @session_logs = @profile.session_logs.recent

    if params[:session_type].present?
      @session_logs = @session_logs.where(session_type: params[:session_type])
    end

    if params[:date_from].present?
      @session_logs = @session_logs.where("date >= ?", params[:date_from])
    end

    if params[:date_to].present?
      @session_logs = @session_logs.where("date <= ?", params[:date_to])
    end

    @session_logs = @session_logs.limit(50)
  end

  def new
    @session_log = @profile.session_logs.new(date: Date.current)
  end

  def create
    @session_log = @profile.session_logs.new(session_log_params)

    if @session_log.save
      redirect_to session_log_path(@session_log), notice: "Session logged."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @session_log = @profile.session_logs.find(params[:id])
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def session_log_params
    params.require(:session_log).permit(
      :planned_session_id,
      :session_type,
      :date,
      :duration_minutes,
      :perceived_exertion,
      :energy_level,
      :skin_condition,
      :finger_soreness,
      :general_soreness,
      :mood,
      :notes,
      :raw_input
    )
  end
end
