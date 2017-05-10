class AddTokenToTournament < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :token, :string, limit: 255
  end
end
