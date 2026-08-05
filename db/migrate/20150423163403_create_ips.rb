class CreateIps < ActiveRecord::Migration[4.2]
  def change
    create_table :ips do |t|
      t.string :address, null: false
      t.integer :player_id, null: false
      t.string :origin, null: false
      t.string :created_at, null:false
    end
  end
end
