class AddLastChatAtToPlayers < ActiveRecord::Migration
  def up
    add_column :players, :last_chat_at, :timestamp
    
    Player.update_all('last_chat_at = updated_at')
  end

  def down
    remove_column :players, :last_chat_at
  end
end
