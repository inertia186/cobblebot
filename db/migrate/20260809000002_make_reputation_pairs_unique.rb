class MakeReputationPairsUnique < ActiveRecord::Migration[7.0]
  INDEX_NAME = 'index_reputation_on_truster_id_and_trustee_id'

  class ReputationRecord < ActiveRecord::Base
    self.table_name = 'reputations'
  end

  def up
    duplicate_pairs.each do |truster_id, trustee_id|
      matches = ReputationRecord.where(
        truster_id: truster_id,
        trustee_id: trustee_id
      )
      matches.where.not(id: matches.minimum(:id)).delete_all
    end

    remove_index :reputations, name: INDEX_NAME
    add_index :reputations, [:truster_id, :trustee_id],
      unique: true,
      name: INDEX_NAME
  end

  def down
    remove_index :reputations, name: INDEX_NAME
    add_index :reputations, [:truster_id, :trustee_id], name: INDEX_NAME
  end

private
  def duplicate_pairs
    ReputationRecord.group(:truster_id, :trustee_id)
      .having('COUNT(*) > 1')
      .pluck(:truster_id, :trustee_id)
  end
end
