class CreateBenchmarkHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :benchmark_histories do |t|
      t.references :benchmark, null: false, foreign_key: true
      t.string :value
      t.date :tested_at
      t.text :notes

      t.timestamps
    end
  end
end
