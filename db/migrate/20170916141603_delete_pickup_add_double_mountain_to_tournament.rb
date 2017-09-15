class DeletePickupAddDoubleMountainToTournament < ActiveRecord::Migration[5.0]
  def change
    remove_column :tournaments, :pickup, :boolean
    add_column :tournaments, :double_mountain, :boolean, default: false
  end
end
