class Mute < ActiveRecord::Base
  belongs_to :player
  belongs_to :muted_player, class_name: 'Player'

  validate do |mute|
    errors.add(:player, "cannot mute self") if mute.player == mute.muted_player
    errors.add(:muted_player, "already muted") if mute.player.muted_players.include?(mute.muted_player)
  end
end