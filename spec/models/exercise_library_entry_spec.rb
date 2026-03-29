require "rails_helper"

RSpec.describe ExerciseLibraryEntry, type: :model do
  it "is valid with required attributes" do
    entry = build(:exercise_library_entry)
    expect(entry).to be_valid
  end

  it "requires name, category, slug, youtube_video_id" do
    entry = ExerciseLibraryEntry.new
    expect(entry).not_to be_valid
    expect(entry.errors[:name]).to be_present
    expect(entry.errors[:category]).to be_present
    expect(entry.errors[:slug]).to be_present
    expect(entry.errors[:youtube_video_id]).to be_present
  end

  it "generates a slug and searchable_text" do
    entry = create(:exercise_library_entry, name: "Max Hangs")
    expect(entry.slug).to eq("max-hangs")
    expect(entry.searchable_text).to include("max hangs")
  end

  it "enforces unique youtube_video_id" do
    create(:exercise_library_entry, youtube_video_id: "dup123")
    dup = build(:exercise_library_entry, youtube_video_id: "dup123")
    expect(dup).not_to be_valid
  end

  it "exposes youtube embed url" do
    entry = build(:exercise_library_entry, youtube_video_id: "xyz987")
    expect(entry.youtube_embed_url).to include("xyz987")
  end
end
