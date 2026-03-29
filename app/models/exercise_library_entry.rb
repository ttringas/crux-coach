class ExerciseLibraryEntry < ApplicationRecord
  CATEGORIES = %w[climbing hangboard board strength cardio mobility warm_up].freeze

  validates :name, :slug, :category, :youtube_video_id, presence: true
  validates :slug, :youtube_video_id, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }

  before_validation :normalize_tags
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }
  before_validation :build_searchable_text

  def to_param
    slug
  end

  def youtube_embed_url
    "https://www.youtube.com/embed/#{youtube_video_id}?rel=0"
  end

  def display_tags
    tags.presence || []
  end

  private

  def normalize_tags
    self.tags = Array(tags).map(&:to_s).map(&:strip).reject(&:blank?)
  end

  def generate_slug
    base = name.to_s.parameterize
    candidate = base
    suffix = 2

    while self.class.where.not(id: id).exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end

  def build_searchable_text
    pieces = [name, video_title, channel_name, description, category]
    pieces.concat(display_tags)
    self.searchable_text = pieces.compact.join(" ").downcase
  end
end
