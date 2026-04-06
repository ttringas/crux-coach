require "rails_helper"

RSpec.describe ExerciseLibrary::Importer do
  describe ".import_from_json!" do
    let(:exercises_data) do
      {
        "exercises" => [
          {
            "name" => "Max Hangs",
            "category" => "hangboard",
            "tags" => ["finger strength", "hangboard"],
            "youtube_video_id" => "vid_maxhangs",
            "video_title" => "Max Hang Protocol",
            "channel" => "Lattice Training",
            "description" => "How to do max hangs properly",
            "duration_estimate" => "8 min"
          },
          {
            "name" => "Campus Board Ladders",
            "category" => "board",
            "tags" => ["power", "campus"],
            "youtube_video_id" => "vid_campus",
            "video_title" => "Campus Board Training",
            "channel_name" => "Power Company",
            "description" => "Campus board technique",
            "duration_estimate" => "10 min"
          }
        ]
      }
    end

    let(:json_path) { Rails.root.join("tmp", "test_exercises.json").to_s }

    before do
      File.write(json_path, JSON.generate(exercises_data))
    end

    after do
      File.delete(json_path) if File.exist?(json_path)
    end

    it "imports exercises from a JSON file" do
      expect {
        described_class.import_from_json!(json_path)
      }.to change(ExerciseLibraryEntry, :count).by(2)

      entry = ExerciseLibraryEntry.find_by(youtube_video_id: "vid_maxhangs")
      expect(entry.name).to eq("Max Hangs")
      expect(entry.category).to eq("hangboard")
      expect(entry.tags).to eq(["finger strength", "hangboard"])
      expect(entry.channel_name).to eq("Lattice Training")
    end

    it "handles channel_name from either 'channel' or 'channel_name' key" do
      described_class.import_from_json!(json_path)

      entry1 = ExerciseLibraryEntry.find_by(youtube_video_id: "vid_maxhangs")
      entry2 = ExerciseLibraryEntry.find_by(youtube_video_id: "vid_campus")

      expect(entry1.channel_name).to eq("Lattice Training")
      expect(entry2.channel_name).to eq("Power Company")
    end

    it "skips duplicates by finding existing records via youtube_video_id" do
      described_class.import_from_json!(json_path)

      expect {
        described_class.import_from_json!(json_path)
      }.not_to change(ExerciseLibraryEntry, :count)
    end

    it "updates existing records when re-imported" do
      described_class.import_from_json!(json_path)

      entry = ExerciseLibraryEntry.find_by(youtube_video_id: "vid_maxhangs")
      expect(entry.name).to eq("Max Hangs")

      exercises_data["exercises"][0]["name"] = "Max Hangs (Updated)"
      File.write(json_path, JSON.generate(exercises_data))

      described_class.import_from_json!(json_path)

      entry.reload
      expect(entry.name).to eq("Max Hangs (Updated)")
    end

    it "handles a plain array format (without exercises wrapper)" do
      plain_array = exercises_data["exercises"]
      File.write(json_path, JSON.generate(plain_array))

      expect {
        described_class.import_from_json!(json_path)
      }.to change(ExerciseLibraryEntry, :count).by(2)
    end
  end
end
