class CreatePlayers < ActiveRecord::Migration
  def change
    create_table :players do |t|
      t.string :uuid
      t.string :nick
      t.string :last_nick
      t.string :last_ip
      t.string :last_chat
      t.timestamp :last_login_at
      t.timestamp :last_logout_at
      t.timestamp :registered_at
      t.timestamp :vetted_at
      t.timestamps null: false
    end
  end
end
