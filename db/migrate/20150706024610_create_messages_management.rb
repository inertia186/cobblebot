class CreateMessagesManagement < ActiveRecord::Migration
  def up
    add_column :messages, :deleted_at, :timestamp
    
    create_table :mutes do |t|
      t.integer :player_id, null: false
      t.integer :muted_player_id, null: false
      t.timestamp :created_at, null:false
    end
  end
  
  def down
    drop_table :mutes
    
    remove_column :messages, :deleted_at
  end
end
