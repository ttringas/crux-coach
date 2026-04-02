class MigrateTrainingAgeToYears < ActiveRecord::Migration[7.1]
  def up
    add_column :climber_profiles, :training_age_years, :decimal, precision: 4, scale: 2

    execute <<~SQL
      UPDATE climber_profiles
      SET training_age_years = training_age_months / 12.0
      WHERE training_age_months IS NOT NULL
    SQL

    remove_column :climber_profiles, :training_age_months
  end

  def down
    add_column :climber_profiles, :training_age_months, :integer

    execute <<~SQL
      UPDATE climber_profiles
      SET training_age_months = ROUND(training_age_years * 12)
      WHERE training_age_years IS NOT NULL
    SQL

    remove_column :climber_profiles, :training_age_years
  end
end
