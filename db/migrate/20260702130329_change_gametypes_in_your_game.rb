class ChangeGametypesInYourGame < ActiveRecord::Migration[8.1]
  def change
    change_column :games, :game_type, :integer, default: 0, null: false
  end
end
