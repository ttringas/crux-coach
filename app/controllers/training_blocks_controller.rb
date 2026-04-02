require "ostruct"

class TrainingBlocksController < ApplicationController
  before_action :set_profile

  def index
    all_blocks = @profile.training_blocks.includes(weekly_plans: :planned_sessions).order(created_at: :desc)

    @active_blocks = all_blocks.select(&:active?)
    @completed_blocks = all_blocks.select(&:completed?)

    # Build week data for each active block
    @active_block_data = @active_blocks.map do |block|
      existing_plans = block.weekly_plans.sort_by(&:week_number)
      weekly_plans = build_all_weeks_for(block, existing_plans)
      current_week_index = determine_current_week_index_for(block, weekly_plans)
      { block: block, weekly_plans: weekly_plans, current_week_index: current_week_index }
    end

    # Legacy support: set @training_block for the generate form's "complete current" messaging
    @training_block = @active_blocks.first
    @generation_status = @profile.training_block_generation_status
    @generation_error = @profile.training_block_generation_error

    if params[:generation_notice].present?
      flash.now[:notice] = params[:generation_notice]
    end
  end

  def create
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    comments = params[:comments].to_s
    training_days = Array(params[:training_days]).select(&:present?)
    activities = Array(params[:activities]).select(&:present?)

    weeks_planned = ((end_date - start_date).to_i / 7.0).ceil
    weeks_planned = [ weeks_planned, 1 ].max

    @profile.update!(
      training_block_generation_status: "pending",
      training_block_generation_error: nil,
      training_block_generation_training_block_id: nil
    )

    GenerateTrainingBlockJob.perform_later(
      climber_profile_id: @profile.id,
      start_date: start_date.to_s,
      end_date: end_date.to_s,
      weeks_planned: weeks_planned,
      comments: comments,
      training_days: training_days,
      activities: activities
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          ActionView::RecordIdentifier.dom_id(@profile, :training_block_generation),
          partial: "training_blocks/generation_pending",
          locals: { profile: @profile }
        )
      end
      format.html { redirect_to training_blocks_path, notice: "Training block is being generated..." }
    end
  rescue StandardError => e
    @profile.update(
      training_block_generation_status: "failed",
      training_block_generation_error: e.message
    )

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          ActionView::RecordIdentifier.dom_id(@profile, :training_block_generation),
          partial: "training_blocks/generation_error",
          locals: { profile: @profile, message: e.message }
        ), status: :unprocessable_entity
      end
      format.html { redirect_to training_blocks_path, alert: e.message }
    end
  end

  def status
    case @profile.training_block_generation_status
    when "pending"
      render json: { status: "pending" }
    when "completed"
      training_block = @profile.training_blocks.find_by(id: @profile.training_block_generation_training_block_id) ||
        @profile.training_blocks.order(created_at: :desc).first

      if training_block
        render json: {
          status: "completed",
          training_block_id: training_block.id,
          notice: "Your new training block is ready and now visible below.",
          html: render_to_string(
            partial: "training_blocks/generation_complete",
            formats: [ :html ],
            locals: { training_block: training_block }
          )
        }
      else
        render json: { status: "idle" }
      end
    when "failed"
      render json: {
        status: "failed",
        html: render_to_string(
          partial: "training_blocks/generation_error",
          formats: [ :html ],
          locals: { profile: @profile, message: @profile.training_block_generation_error }
        )
      }
    else
      render json: { status: "idle" }
    end
  end

  def regenerate
    @training_block = @profile.training_blocks.find(params[:id])
    comments = params[:comments].to_s

    Ai::TrainingBlockGenerator.regenerate_future!(
      training_block: @training_block,
      comments: comments
    )

    redirect_to training_blocks_path, notice: "Future sessions regenerated!"
  rescue Ai::Client::Error => e
    redirect_to training_blocks_path, alert: "Regeneration failed: #{e.message}"
  end

  def complete
    @training_block = @profile.training_blocks.find(params[:id])

    ActiveRecord::Base.transaction do
      today = Date.current
      @training_block.weekly_plans.each do |wp|
        if wp.week_of > today
          wp.planned_sessions.destroy_all
          wp.destroy!
        else
          wp.planned_sessions.where(status: :todo).where("day_of_week > ?", (today.wday + 6) % 7).each do |ps|
            session_date = wp.week_of + ps.day_of_week
            ps.destroy! if session_date > today
          end
        end
      end
      @training_block.update!(status: :completed, ends_at: today)
    end

    redirect_to training_blocks_path, notice: "Training block completed. You can now generate a new one."
  end

  private

  def set_profile
    @profile = current_climber_profile
  end

  def build_all_weeks_for(block, existing_plans)
    return existing_plans unless block.weeks_planned && block.started_at

    plans_by_week = existing_plans.index_by(&:week_number)
    (1..block.weeks_planned).map do |week_num|
      plans_by_week[week_num] || OpenStruct.new(
        week_number: week_num,
        week_of: block.started_at + (week_num - 1).weeks,
        week_focus: nil,
        summary: nil,
        status: "not_generated",
        planned_sessions: PlannedSession.none
      )
    end
  end

  def determine_current_week_index_for(block, weekly_plans)
    return 0 unless block&.started_at
    today = Date.current
    weekly_plans.each_with_index do |wp, i|
      return i if wp.week_of <= today && (wp.week_of + 6) >= today
    end
    weekly_plans.size - 1
  end
end
