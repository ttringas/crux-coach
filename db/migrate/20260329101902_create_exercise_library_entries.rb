class CreateExerciseLibraryEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :exercise_library_entries do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :category, null: false
      t.jsonb :tags, null: false, default: []
      t.string :youtube_video_id, null: false
      t.string :video_title
      t.string :channel_name
      t.text :description
      t.string :duration_estimate
      t.text :searchable_text

      t.timestamps
    end

    add_index :exercise_library_entries, :slug, unique: true
    add_index :exercise_library_entries, :youtube_video_id, unique: true
    add_index :exercise_library_entries, :category
  end
end
