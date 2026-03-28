class CreateWeeklyPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_plans do |t|
      t.references :training_block, null: false, foreign_key: true
      t.references :climber_profile, null: false, foreign_key: true
      t.integer :week_number
      t.date :week_of
      t.integer :status, null: false, default: 0
      t.jsonb :ai_generated_plan, null: false, default: {}
      t.boolean :coach_modified, null: false, default: false
      t.text :coach_notes
      t.text :summary

      t.timestamps
    end

    add_index :weekly_plans, :status
    add_index :weekly_plans, :week_of
    add_index :weekly_plans, [:climber_profile_id, :week_of], unique: true
  end
end
