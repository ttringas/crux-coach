class CreatePlannedSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :planned_sessions do |t|
      t.references :weekly_plan, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.integer :session_type, null: false
      t.string :title
      t.text :description
      t.integer :estimated_duration_minutes
      t.integer :intensity, null: false
      t.jsonb :exercises, null: false, default: []

      t.timestamps
    end

    add_index :planned_sessions, :session_type
    add_index :planned_sessions, [:weekly_plan_id, :day_of_week]
  end
end
