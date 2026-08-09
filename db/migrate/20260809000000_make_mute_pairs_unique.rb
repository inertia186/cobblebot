class MakeMutePairsUnique < ActiveRecord::Migration[7.0]
  INDEX_NAME = 'index_mutes_on_player_id_and_muted_player_id'

  class MuteRecord < ActiveRecord::Base
    self.table_name = 'mutes'
  end

  def up
    duplicate_pairs.each do |player_id, muted_player_id|
      matches = MuteRecord.where(player_id: player_id, muted_player_id: muted_player_id)
      matches.where.not(id: matches.minimum(:id)).delete_all
    end

    remove_index :mutes, name: INDEX_NAME
    add_index :mutes, [:player_id, :muted_player_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_index :mutes, name: INDEX_NAME
    add_index :mutes, [:player_id, :muted_player_id], name: INDEX_NAME
  end

private
  def duplicate_pairs
    MuteRecord.group(:player_id, :muted_player_id)
      .having('COUNT(*) > 1')
      .pluck(:player_id, :muted_player_id)
  end
end
