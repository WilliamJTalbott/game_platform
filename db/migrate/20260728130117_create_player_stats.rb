class CreatePlayerStats < ActiveRecord::Migration[8.1]
  def change
    create_view :player_stats
  end
end
