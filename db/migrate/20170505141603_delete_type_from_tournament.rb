class DeleteTypeFromTournament < ActiveRecord::Migration[5.0]
  def change
    remove_column :tournaments, :type, :string, limit: 255
  end
end
