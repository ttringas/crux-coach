class AddLoggingFieldsToPlannedSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :planned_sessions, :status, :integer, default: 0, null: false
    add_column :planned_sessions, :started_at, :datetime
    add_column :planned_sessions, :completed_at, :datetime
    add_column :planned_sessions, :session_notes, :text
    add_column :planned_sessions, :exercise_logs, :jsonb, default: [], null: false
    add_column :planned_sessions, :perceived_exertion, :integer
    add_column :planned_sessions, :energy_level, :integer
    add_column :planned_sessions, :finger_soreness, :integer
    add_column :planned_sessions, :general_soreness, :integer
  end
end
