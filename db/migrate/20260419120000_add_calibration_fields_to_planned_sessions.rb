class AddCalibrationFieldsToPlannedSessions < ActiveRecord::Migration[8.0]
  def change
    change_table :planned_sessions, bulk: true do |t|
      t.string :calibration_status
      t.text :calibration_error
      t.text :calibration_feedback
      t.text :calibration_reasoning
      t.datetime :calibration_requested_at
      t.datetime :calibration_completed_at
      t.jsonb :previous_exercises
    end
  end
end
