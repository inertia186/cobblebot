class ShallUpdateStatsToPlayers < ActiveRecord::Migration[4.2]
  def change
    add_column :players, :shall_update_stats, :boolean, null: false, default: false
  end
end
