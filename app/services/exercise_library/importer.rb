require "json"

module ExerciseLibrary
  class Importer
    DEFAULT_PATH = Rails.root.join("db", "seeds", "exercise_library.json").to_s.freeze

    def self.import_from_json!(path = DEFAULT_PATH)
      payload = JSON.parse(File.read(path))
      exercises = payload.is_a?(Hash) ? payload.fetch("exercises", []) : Array(payload)

      exercises.each do |entry|
        attrs = map_entry(entry)
        record = ExerciseLibraryEntry.find_or_initialize_by(youtube_video_id: attrs[:youtube_video_id])
        record.assign_attributes(attrs)
        record.save!
      end
    end

    def self.map_entry(entry)
      {
        name: entry["name"],
        category: entry["category"],
        tags: entry["tags"] || [],
        youtube_video_id: entry["youtube_video_id"],
        video_title: entry["video_title"],
        channel_name: entry["channel"] || entry["channel_name"],
        description: entry["description"],
        duration_estimate: entry["duration_estimate"]
      }
    end
  end
end
