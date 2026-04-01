class CreateSessionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :session_logs do |t|
      t.references :climber_profile, null: false, foreign_key: true
      t.references :planned_session, null: true, foreign_key: true
      t.integer :session_type, null: false
      t.date :date, null: false
      t.integer :duration_minutes
      t.integer :perceived_exertion
      t.integer :energy_level
      t.integer :skin_condition
      t.integer :finger_soreness
      t.integer :general_soreness
      t.integer :mood
      t.text :notes
      t.text :raw_input
      t.jsonb :structured_data, null: false, default: {}
      t.jsonb :climbs_logged, null: false, default: []
      t.jsonb :exercises_logged, null: false, default: []

      t.timestamps
    end

    add_index :session_logs, :date
    add_index :session_logs, :session_type
    add_index :session_logs, [ :climber_profile_id, :date ]
  end
end
