class AddMutedAtToPlayers < ActiveRecord::Migration
  def change
    add_column :players, :muted_at, :timestamp
  end
end
