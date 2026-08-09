class DenormalizeStats < ActiveRecord::Migration[4.2]
  def up
    add_column :players, :leave_game, :integer, default: 0, null: false
    add_column :players, :deaths, :integer, default: 0, null: false
    add_column :players, :mob_kills, :integer, default: 0, null: false
    add_column :players, :time_since_death, :integer, default: 0, null: false
    add_column :players, :player_kills, :integer, default: 0, null: false
    
    players = Player.where(leave_game: 0, deaths: 0, mob_kills: 0, time_since_death: 0, player_kills: 0)
    count = players.count
    label = count == 1 ? 'player' : 'players'
    puts "Looking up #{count} #{label} to populate stats.  ^C to safely retry this migration later."
    
    players.find_each do |player|
      backfill_stats(player)

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

  private

  def backfill_stats(player)
    stats = player.stat
    player.update_columns(
      leave_game: stats.leave_game,
      deaths: stats.deaths,
      mob_kills: stats.mob_kills,
      time_since_death: stats.time_since_death,
      player_kills: stats.player_kills
    )
  end
end
