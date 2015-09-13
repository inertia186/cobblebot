class DenormalizeStats < ActiveRecord::Migration
  def up
    add_column :players, :leave_game, :integer, default: 0, null: false
    add_column :players, :deaths, :integer, default: 0, null: false
    add_column :players, :mob_kills, :integer, default: 0, null: false
    add_column :players, :time_since_death, :integer, default: 0, null: false
    add_column :players, :player_kills, :integer, default: 0, null: false
    
    players = Player.where(leave_game: 0, deaths: 0, mob_kills: 0, time_since_death: 0, player_kills: 0)
    count = players.count
    puts "Looking up #{pluralize(count, 'player')} to populate stats.  ^C to safely retry this migration later."
    
    players.find_each do |player|
      player.update_column(:leave_game, player.stat.leave_game) rescue 0
      player.update_column(:deaths, player.stat.deaths) rescue 0
      player.update_column(:mob_kills, player.stat.mob_kills) rescue 0
      player.update_column(:time_since_death, player.stat.time_since_death) rescue 0
      player.update_column(:player_kills, player.stat.player_kills) rescue 0

      print '.'
    end
    
    puts "\nDone."
  end
  
  def down
    remove_column :players, :leave_game
    remove_column :players, :deaths
    remove_column :players, :mob_kills
    remove_column :players, :time_since_death
    remove_column :players, :player_kills
  end
end
