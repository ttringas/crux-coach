class CreateTrainingBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :training_blocks do |t|
      t.references :climber_profile, null: false, foreign_key: true
      t.string :name
      t.integer :focus, null: false
      t.integer :weeks_planned
      t.integer :week_number
      t.date :started_at
      t.date :ends_at
      t.integer :status, null: false, default: 0
      t.text :ai_reasoning

      t.timestamps
    end

    add_index :training_blocks, :status
    add_index :training_blocks, :focus
    add_index :training_blocks, [:climber_profile_id, :status]
  end
end
