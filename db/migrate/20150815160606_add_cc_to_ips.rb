include ActionView::Helpers::TextHelper

class AddCcToIps < ActiveRecord::Migration
  def up
    add_column :ips, :cc, :string
    add_index :ips, [:cc, :player_id], name: :index_ips_on_cc_and_player_id

    ips = Ip.where(cc: nil).pluck(:address).uniq
    count = ips.count
    estimation = (count / 25) / 60
    puts "Looking up #{pluralize(count, 'IP address')} to populate country code.  This will take approximately #{pluralize(estimation, 'minute')}.  ^C to safely retry this migration later."
    
    ips.each do |ip|
      break unless !!Ip.send(:update_cc, ip)
      
      print '.'
    end
    
    puts "\nDone."
  end
  
  def down
    remove_column :ips, :cc
  end
end
