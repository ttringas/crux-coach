class CreateCoachAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :coach_assignments do |t|
      t.references :coach, null: false, foreign_key: true
      t.references :climber_profile, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :ended_at
      t.text :coach_notes

      t.timestamps
    end

    add_index :coach_assignments, :status
    add_index :coach_assignments, [:coach_id, :status]
    add_index :coach_assignments, [:climber_profile_id, :status]
  end
end
