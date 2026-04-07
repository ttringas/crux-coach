class AddGenerationStartedAtToClimberProfiles < ActiveRecord::Migration[8.0]
  def change
    add_column :climber_profiles, :training_block_generation_started_at, :datetime
  end
end
