class AddStartedAtToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :started_at, :datetime
  end
end
