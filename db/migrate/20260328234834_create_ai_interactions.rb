class CreateAiInteractions < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_interactions do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :interaction_type, null: false
      t.string :provider
      t.string :model
      t.text :prompt
      t.text :response
      t.integer :tokens_used
      t.integer :duration_ms
      t.integer :cost_cents

      t.timestamps
    end

    add_index :ai_interactions, :interaction_type
    add_index :ai_interactions, [ :user_id, :interaction_type ]
  end
end
