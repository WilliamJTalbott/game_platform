class AddHostToParticipants < ActiveRecord::Migration[8.1]
  def up
    add_column :participants, :host, :boolean, default: false, null: false

    execute <<~SQL
      UPDATE participants SET host = true WHERE id IN (
        SELECT DISTINCT ON (game_id) id FROM participants ORDER BY game_id, created_at
      )
    SQL
  end

  def down
    remove_column :participants, :host
  end
end
