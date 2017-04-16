class ChangeComment < ActiveRecord::Migration
  def self.up
    change_column :games, :comment, :string, limit: 50
  end

  def self.down
    change_column :games, :comment, :string, limit: 24
  end
end
