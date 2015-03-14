class CreateServerCallbacks < ActiveRecord::Migration
  def change
    create_table :server_callbacks do |t|
      t.string :name, null: false
      t.string :pattern, null: false
      t.string :match_scheme, null: false, default: 'player_chat'
      t.text :command, null: false
      t.timestamp :ran_at
      t.string :cooldown, null: false, default: '+0 seconds'
      t.boolean :enabled, null: false, default: '1'
      t.timestamps null: false
    end
  end
end
