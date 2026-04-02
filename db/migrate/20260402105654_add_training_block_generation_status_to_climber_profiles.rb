class AddTrainingBlockGenerationStatusToClimberProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :climber_profiles, :training_block_generation_status, :string
    add_column :climber_profiles, :training_block_generation_error, :text
    add_column :climber_profiles, :training_block_generation_training_block_id, :bigint
  end
end
