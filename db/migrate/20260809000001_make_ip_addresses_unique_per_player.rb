class MakeIpAddressesUniquePerPlayer < ActiveRecord::Migration[7.0]
  INDEX_NAME = 'index_ips_on_address_and_player_id'

  class IpRecord < ActiveRecord::Base
    self.table_name = 'ips'
  end

  def up
    duplicate_pairs.each do |address, player_id|
      matches = IpRecord.where(address: address, player_id: player_id)
      matches.where.not(id: matches.minimum(:id)).delete_all
    end

    remove_index :ips, name: INDEX_NAME
    add_index :ips, [:address, :player_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_index :ips, name: INDEX_NAME
    add_index :ips, [:address, :player_id], name: INDEX_NAME
  end

private
  def duplicate_pairs
    IpRecord.group(:address, :player_id)
      .having('COUNT(*) > 1')
      .pluck(:address, :player_id)
  end
end
