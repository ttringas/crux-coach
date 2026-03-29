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
    @session_log = @profile.session_logs.new
    raw_input = params.dig(:session_log, :raw_input).to_s.strip

    if raw_input.present?
      parsed = parsed_payload_from_params
      parsed ||= Ai::SessionParser.call(raw_text: raw_input, climber_profile: @profile)

      apply_parsed_session(@session_log, parsed, raw_input)
      @session_log.assign_attributes(session_log_params.except(:session_type, :duration_minutes, :perceived_exertion))
    else
      @session_log.assign_attributes(session_log_params)
    end

    if @session_log.save
      redirect_to session_log_path(@session_log), notice: "Session logged."
    else
      render :new, status: :unprocessable_entity
    end
  rescue Ai::Client::Error => e
    flash.now[:alert] = e.message
    @session_log ||= @profile.session_logs.new(session_log_params)
    render :new, status: :unprocessable_entity
  end

  def show
    @session_log = @profile.session_logs.find(params[:id])
  end

  def parse
    raw_input = params.dig(:session_log, :raw_input).to_s.strip
    if raw_input.blank?
      return respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = "Please describe your session before parsing."
          render turbo_stream: turbo_stream.replace(
            "session_parse_preview",
            partial: "session_logs/parse_preview",
            locals: { error: "Please describe your session before parsing." }
          )
        end
        format.json { render json: { error: "Raw input is required." }, status: :unprocessable_entity }
      end
    end

    parsed = Ai::SessionParser.call(raw_text: raw_input, climber_profile: @profile)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "session_parse_preview",
          partial: "session_logs/parse_preview",
          locals: { parsed: parsed, raw_input: raw_input }
        )
      end
      format.json { render json: parsed }
    end
  rescue Ai::Client::Error => e
    respond_to do |format|
      format.turbo_stream do
        flash.now[:alert] = e.message
        render turbo_stream: turbo_stream.replace(
          "session_parse_preview",
          partial: "session_logs/parse_preview",
          locals: { error: e.message }
        )
      end
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
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

  def parsed_payload_from_params
    payload = params.dig(:session_log, :structured_data)
    return if payload.blank?
    return payload if payload.is_a?(Hash)

    JSON.parse(payload)
  rescue JSON::ParserError
    nil
  end

  def apply_parsed_session(session_log, parsed, raw_input)
    session_log.raw_input = raw_input
    session_log.structured_data = parsed
    session_log.climbs_logged = Array(parsed["climbs_logged"])
    session_log.exercises_logged = Array(parsed["exercises_logged"])

    session_type = parsed["session_type"].to_s.downcase
    session_log.session_type = SessionLog.session_types.key?(session_type) ? session_type : "climbing"

    session_log.duration_minutes = parsed["duration_minutes"] if parsed["duration_minutes"].present?
    session_log.perceived_exertion = parsed["perceived_exertion"] if parsed["perceived_exertion"].present?
  end
end
