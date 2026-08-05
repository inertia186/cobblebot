class AddAddressPlayerIndexOnIps < ActiveRecord::Migration[4.2]
  def change
    add_index :ips, [:address, :player_id], name: :index_ips_on_address_and_player_id
  end
end
