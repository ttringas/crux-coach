class UpdateAvailableEquipmentOptions < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE climber_profiles
      SET available_equipment = (
        SELECT ARRAY(
          SELECT DISTINCT mapped_item
          FROM (
            SELECT CASE
              WHEN item IN ('kilter', 'moonboard', 'tension') THEN 'training_board'
              WHEN item = 'rings' THEN 'rings_trx'
              ELSE item
            END AS mapped_item
            FROM unnest(available_equipment) AS item
          ) mapped_items
        )
      )
    SQL
  end

  def down
    execute <<~SQL
      UPDATE climber_profiles
      SET available_equipment = (
        SELECT ARRAY(
          SELECT DISTINCT mapped_item
          FROM (
            SELECT CASE
              WHEN item = 'rings_trx' THEN 'rings'
              ELSE item
            END AS mapped_item
            FROM unnest(available_equipment) AS item
          ) mapped_items
        )
      )
    SQL
  end
end
