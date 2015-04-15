require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_stats
    player = Player.find_by_nick('inertia186')

    refute_nil player.stats, 'did not expect nil stats'
    refute_nil player.stats.mob_kills, 'did not expect nil stats.mob_kills'
    refute_nil player.send('stat.mobKills'), 'did not expect nil stats.mob_kills'
  end

  def test_missing_method
    Player.all.find_each do |player|
      assert player.itself, "expect method to exist"
    
      begin
        refute player.method_that_does_not_exist, 'did not expect method to exist'
        # :nocov:
        fail 'did not expect method to exist'
        # :nocov:
      rescue NoMethodError => e
        # success
      end
    end
  end
end