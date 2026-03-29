require "rails_helper"

RSpec.describe ExerciseLibrary::Matcher do
  it "matches exact exercise names" do
    entry = create(:exercise_library_entry, name: "Max Hangs", youtube_video_id: "maxhangs1")
    matcher = described_class.new(entries: ExerciseLibraryEntry.all)

    expect(matcher.match("Max Hangs")).to eq(entry)
  end

  it "matches close names by token overlap" do
    entry = create(:exercise_library_entry, name: "Weighted Pull-ups", youtube_video_id: "pullups1")
    matcher = described_class.new(entries: ExerciseLibraryEntry.all)

    expect(matcher.match("weighted pull ups")).to eq(entry)
  end

  it "returns nil for unrelated names" do
    create(:exercise_library_entry, name: "Hip Mobility Flow", youtube_video_id: "mob1")
    matcher = described_class.new(entries: ExerciseLibraryEntry.all)

    expect(matcher.match("Fingerboard repeaters")).to be_nil
  end

  it "maps matches for exercise arrays" do
    entry = create(:exercise_library_entry, name: "Silent Feet", youtube_video_id: "feet1")
    matcher = described_class.new(entries: ExerciseLibraryEntry.all)

    matches = matcher.match_exercises([
      { "name" => "Silent Feet" },
      { "name" => "Unknown" }
    ])

    expect(matches[0]).to eq(entry)
    expect(matches[1]).to be_nil
  end
end
