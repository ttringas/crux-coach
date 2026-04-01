class AddOverallFocusToTrainingBlocks < ActiveRecord::Migration[8.0]
  def change
    add_column :training_blocks, :overall_focus, :text
    add_column :weekly_plans, :week_focus, :string
  end
end
