class AddProfileImagesToTournament < ActiveRecord::Migration[5.0]
  def change
    add_column :tournaments, :profile_images, :boolean, default: false
  end
end
