class AddStateCityToIps < ActiveRecord::Migration[4.2]
  def change
    add_column :ips, :state, :string
    add_column :ips, :city, :string
  end
end
