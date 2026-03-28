class CreateCoaches < ActiveRecord::Migration[8.0]
  def change
    create_table :coaches do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :bio
      t.text :specialties, array: true, default: [], null: false
      t.integer :years_coaching
      t.string :max_grade_boulder
      t.string :max_grade_sport
      t.decimal :rate_per_month, precision: 8, scale: 2
      t.boolean :accepting_athletes, null: false, default: true

      t.timestamps
    end

    add_index :coaches, :accepting_athletes
  end
end
