class CreateLinks < ActiveRecord::Migration
  def change
    create_table :links do |t|
      t.string :url, null: false
      t.string :title
      t.integer :actor_id
      t.string :actor_type
      t.timestamp :expires_at
      t.timestamp :last_modified_at
      t.boolean :can_embed
      t.timestamps null: false
    end
  end
end
