class CreatePlayerIndicies < ActiveRecord::Migration
  def change
    add_index :links, [:actor_type, :actor_id], name: 'index_links_on_actor_type_and_actor_id'
    add_index :messages, :author_id, name: 'index_messages_on_author_id'
    add_index :messages, :recipient_id, name: 'index_messages_on_recipient_id'
    add_index :messages, [:type, :author_id], name: 'index_messages_on_type_and_author_id'
    add_index :messages, [:type, :recipient_id], name: 'index_messages_on_type_and_recipient_id'
    add_index :ips, :player_id, name: 'index_ips_on_player_id'
    add_index :mutes, :player_id, name: 'index_mutes_on_player_id'
    add_index :mutes, [:player_id, :muted_player_id], name: 'index_mutes_on_player_id_and_muted_player_id'
  end
end
