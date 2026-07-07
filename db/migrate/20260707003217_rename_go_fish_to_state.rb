class RenameGoFishToState < ActiveRecord::Migration[8.1]
  def change
    rename_column :games, :go_fish, :state
  end
end