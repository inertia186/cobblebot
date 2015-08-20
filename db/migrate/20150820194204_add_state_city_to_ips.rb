class AddStateCityToIps < ActiveRecord::Migration
  def change
    add_column :ips, :state, :string
    add_column :ips, :city, :string
  end
end
