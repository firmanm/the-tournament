class AddTeamsAndResultsToTournament < ActiveRecord::Migration
  def change
    add_column :tournaments, :teams, :json
    add_column :tournaments, :results, :json
  end
end
