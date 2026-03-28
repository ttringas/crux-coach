class CoachesController < ApplicationController
  def index
    @coaches = Coach.includes(:user).order(accepting_athletes: :desc, years_coaching: :desc)
  end

  def show
    @coach = Coach.includes(:user).find(params[:id])
  end
end
