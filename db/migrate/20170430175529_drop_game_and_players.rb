class DropGameAndPlayers < ActiveRecord::Migration
  def up
    drop_table :games
    drop_table :game_records
    drop_table :players
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
