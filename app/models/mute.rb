class Mute < ActiveRecord::Base
  belongs_to :player
  belongs_to :muted_player, class_name: 'Player'

  validates :player, :muted_player, presence: true
  validates :muted_player_id, uniqueness: { scope: :player_id }

  validate do
    if player.present? && muted_player.present? && player == muted_player
      errors.add(:player, 'cannot mute self')
    end
  end
end
