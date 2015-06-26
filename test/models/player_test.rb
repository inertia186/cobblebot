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

  def test_mode
    assert Player.mode
  end

  def test_mode_banned_players
    refute (relation = Player.mode(:banned_players)).any?, "did not expect banned players, got: #{relation.map(&:nick)}"
    assert Player.mode(:banned_players, false).any?, 'expect non-banned players'
  end

  def test_mode_whitelist
    assert Player.mode(:whitelist).any?, 'expect whitelist'
    assert Player.mode(:whitelist, false).any?, 'expect non-whitelist'
  end

  def test_mode_ops
    assert Player.mode(:ops).any?, 'expect ops'
    assert Player.mode(:ops, false).any?, 'expect non-ops'
  end
  
  def test_matching_ip
    Player.last.update_attribute(:last_ip, '127.0.0.1')
    assert Player.matching_last_ip('127.0.0.1').any?, 'expected matching last ip'
    assert Player.matching_last_ip('127.0.0.1', false).any?, 'expected not-matching last ip'
  end

  def test_registered
    Player.last.register!
    assert Player.registered.any?, 'expected registered'
    assert Player.registered(false).any?, 'expected non-registered'
  end

  def test_has_links
    refute (relation = Player.has_links).any?, "did not expect has links, got: #{relation.map(&:nick)}"
    assert Player.has_links(false).any?, 'expected non-has links'
  end

  def test_has_messages
    refute (relation = Player.has_messages).any?, "did not expect has messages, got: #{relation.map(&:nick)}"
    assert Player.has_messages(false).any?, 'expected non-has messages'
  end

  def test_has_tips
    refute (relation = Player.has_tips).any?, "did not expect has tips, got: #{relation.map(&:nick)}"
    assert Player.has_tips(false).any?, 'expected non-has tips'
  end

  def test_has_ips
    assert Player.has_ips.any?, 'expect has ips'
    assert Player.has_ips(false).any?, 'expected non-has ips'
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