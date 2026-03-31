class AddPositionToPlannedSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :planned_sessions, :position, :integer, null: false, default: 0
    add_index :planned_sessions, [:weekly_plan_id, :day_of_week, :position], name: "index_planned_sessions_on_plan_day_position"
  end
end
