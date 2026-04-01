class RemoveUniqueIndexOnWeeklyPlansWeekOf < ActiveRecord::Migration[8.0]
  def change
    remove_index :weekly_plans, [ :climber_profile_id, :week_of ], unique: true
    add_index :weekly_plans, [ :climber_profile_id, :week_of ]
  end
end
