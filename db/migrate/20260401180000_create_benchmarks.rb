class CreateBenchmarks < ActiveRecord::Migration[8.0]
  def change
    create_table :benchmarks do |t|
      t.references :climber_profile, null: false, foreign_key: true
      t.string :benchmark_key, null: false
      t.string :value
      t.string :unit
      t.date :tested_at
      t.text :notes

      t.timestamps
    end

    add_index :benchmarks, [ :climber_profile_id, :benchmark_key ], unique: true
  end
end
