class CreateReputations < ActiveRecord::Migration
  def change
    create_table :reputations do |t|
      t.integer :truster_id
      t.integer :trustee_id
      t.integer :rate
      t.timestamps null: false
    end
    
    add_index :reputations, :truster_id, name: 'index_reputation_on_truster_id'
    add_index :reputations, [:truster_id, :trustee_id], name: 'index_reputation_on_truster_id_and_trustee_id'
  end
end
