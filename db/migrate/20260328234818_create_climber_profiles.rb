class CreateClimberProfiles < ActiveRecord::Migration[8.0]
  def change
    create_table :climber_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.integer :height_inches
      t.integer :wingspan_inches
      t.decimal :weight_lbs, precision: 6, scale: 2
      t.integer :years_climbing
      t.integer :training_age_months
      t.string :current_max_boulder_grade
      t.string :current_max_sport_grade
      t.string :comfortable_boulder_grade
      t.string :comfortable_sport_grade
      t.text :preferred_disciplines, array: true, default: [], null: false
      t.text :available_equipment, array: true, default: [], null: false
      t.integer :weekly_training_days
      t.integer :session_duration_minutes
      t.text :goals_short_term
      t.text :goals_long_term
      t.jsonb :injuries, default: [], null: false
      t.text :style_strengths, array: true, default: [], null: false
      t.text :style_weaknesses, array: true, default: [], null: false
      t.text :additional_context
      t.boolean :onboarding_completed, null: false, default: false

      t.timestamps
    end
  end
end
