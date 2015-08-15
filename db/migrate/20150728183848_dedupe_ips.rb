class DedupeIps < ActiveRecord::Migration
  def up
    Ip.all.group_by { |r| [r.address, r.player_id] }.values.each do |ips|
      first_ip = ips.shift
      
      ips.each { |ip| ip.destroy }
    end
  end
  
  def down
  end
end
