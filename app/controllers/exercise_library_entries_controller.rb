class ExerciseLibraryEntriesController < ApplicationController
  def index
    @categories = ["all"] + ExerciseLibraryEntry::CATEGORIES
    @category = params[:category].presence || "all"
    @query = params[:q].to_s.strip

    entries = ExerciseLibraryEntry.all
    entries = entries.where(category: @category) if @category != "all"

    if @query.present?
      entries = entries.where("searchable_text LIKE ?", "%#{@query.downcase}%")
    end

    @entries = entries.order(:name)
  end

  def show
    @entry = ExerciseLibraryEntry.find_by!(slug: params[:id])
  end
end
