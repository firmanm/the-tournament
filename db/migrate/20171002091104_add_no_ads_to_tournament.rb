class AddNoAdsToTournament < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :no_ads, :boolean, default: false
  end
end
