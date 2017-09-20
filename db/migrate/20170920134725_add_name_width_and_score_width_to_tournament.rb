class AddNameWidthAndScoreWidthToTournament < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :name_width, :string, limit: 255
    add_column :tournaments, :score_width, :string, limit: 255
  end
end
