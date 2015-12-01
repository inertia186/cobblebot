require 'test_helper'

class PlayerTest < ActiveSupport::TestCase
  include WebStubs

  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_max_explore_all_biome_progress
    assert_equal 8, Player.max_explore_all_biome_progress
  end

  def test_to_selector
    expected_selector = '@p[name=inertia186,name=Dinnerbone,name=resnullius]'
    assert_equal expected_selector, Player.all.to_selector
  end

  def test_stats
    player = Player.find_by_nick('inertia186')

    refute_nil player.stats, 'did not expect nil stats'
    refute_nil player.stats.mob_kills, 'did not expect nil stats.mob_kills'
    refute_nil player.send('stat.mobKills'), 'did not expect nil stats.mob_kills'
  end

  def test_mode
    assert Player.mode

    p = players(:inertia186)

    refute p.vetted?, 'did not expect player vetted'
    assert p.opped?, 'expect mode: op'
    assert p.whitelisted?, 'expect mode: whitelisted'
    refute p.banned?, 'did not expect mode: banned'
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
    assert Player.has_messages.any?, 'expect has messages'
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

  def test_has_sent_messages
    assert Player.has_sent_messages.any?, 'expect has sent_messages'
    assert Player.has_sent_messages(false).any?, 'expected non-has sent_messages'
  end

  def test_has_topics
    refute (relation = Player.has_topics).any?, "did not expect has topics, got: #{relation.map(&:nicks)}"
    assert Player.has_topics(false).any?, 'expected non-has topics'
  end

  def test_has_pvp_wins
    assert Player.has_pvp_wins.any?, 'expect has pvp_wins'
    assert Player.has_pvp_wins(false).any?, 'expected non-has pvp_wins'
  end

  def test_has_pvp_losses
    assert Player.has_pvp_losses.any?, 'expect has pvp_losses'
    assert Player.has_pvp_losses(false).any?, 'expected non-has pvp_losses'
  end

  def test_has_reputations
    refute (relation = Player.has_reputations).any?, "did not expect has reputations, got: #{relation.map(&:nicks)}"
    assert Player.has_reputations(false).any?, 'expected non-has reputations'
  end

  def test_has_inverse_reputations
    refute (relation = Player.has_inverse_reputations).any?, "did not expect has inverse_reputations, got: #{relation.map(&:nicks)}"
    assert Player.has_inverse_reputations(false).any?, 'expected non-has inverse_reputations'
  end

  def test_has_donations
    assert Player.has_donations.any?, 'expect has donations'
    assert Player.has_donations(false).any?, 'expected non-has donations'
  end

  def test_has_quotes
    refute (relation = Player.has_quotes).any?, "did not expect has quotes, got: #{relation.map(&:nicks)}"
    assert Player.has_quotes(false).any?, 'expected non-has quotes'
  end

  def test_within_biomes_explored
    assert Player.within_biomes_explored(0, 100).any?, 'expect within_biomes_explored'
    refute (relation = Player.within_biomes_explored(0, 100, false)).any?, "did not expect within_biomes_explored, got: #{relation.map(&:nick)}"
  end

  def test_spammers
    refute (relation = Player.spammers).any?, "did not expect spammers, got: #{relation.map(&:nick)}"
    assert Player.spammers(false).any?, 'did not expect spammers'
  end

  def test_cc
    assert Player.cc('US').any?, 'expect cc'
    assert Player.cc('US', false).any?, 'expect cc'
  end

  def test_lang
    assert Player.lang_en.any?, 'expect lang_en'
    assert Player.lang_en(false).any?, 'expect lang_en'
    refute (relation = Player.lang_fr).any?, "did not expect lang_fr, got: #{relation.map(&:nick)}"
    assert Player.lang_fr(false).any?, 'expect lang_fr'
    refute (relation = Player.lang_pt).any?, "did not expect lang_pt, got: #{relation.map(&:nick)}"
    assert Player.lang_pt(false).any?, 'expect lang_pt'
    assert Player.lang_es.any?, 'expect lang_es'
    assert Player.lang_es(false).any?, 'expect lang_es'
  end

  def test_activity
    assert Player.activity_before(Time.now).any?, 'expect activity_before'
    assert Player.activity_after(Time.at 0).any?, 'expect activity_after'
  end

  def test_updated
    assert Player.updated_before(Time.now).any?, 'expect updated_before'
    assert Player.updated_after(Time.at 0).any?, 'expect updated_after'
  end

  def test_reputation_sum
    truster = players(:inertia186)
    trustee = players(:resnullius)

    assert_nil trustee.reputation_sum, 'invalid reputation query'
    assert_nil trustee.reputation_sum(truster: truster), 'non-reputation query'
  end

  def test_players_with_same_ip
    refute (relation = Player.first.players_with_same_ip).any?, "did not expect players_with_same_ip: #{relation.map(&:nick)}"
  end

  def test_player_logged_in?
    p = players(:inertia186)

    refute p.logged_in?, 'did not expect player logged in'

    Server.mock_mode(up: true, player_nicks: [p.nick]) do
      assert p.logged_in?, 'expect player logged in'
    end
  end

  def test_hours_since_death
    assert_equal "0.00 hours", players(:inertia186).hours_since_death
  end

  def test_total_kills
    assert_equal 0, players(:inertia186).total_kills
  end

  def test_update_stats!
    assert players(:inertia186).update_stats!, 'expect update_stats!'
  end

  def test_toggle_play_sounds!
    assert players(:inertia186).toggle_play_sounds!, 'expect toggle_play_sounds!'
  end

  def test_latest_country_code
    assert_equal '**', players(:inertia186).latest_country_code, 'expect latest_country_code'
  end

  def test_profile
    Player.all.find_each do |p|
      stub_mojang_sessions_server(p.uuid.gsub(/-/, '')) do
        assert p.profile, 'expect profile'
        assert_equal p.nick, p.profile['name']

        p.profile['properties'].each do |property|
          case property['name']
          when 'textures'
            value = property['value']
            data = JSON.parse Base64.decode64(value)
            refute_nil Time.at(data['timestamp'] / 1000)
            assert_equal p.nick, data['profileName']
            assert data['textures'].any?, 'expected textures'
          else
            fail "Unknown property: #{property}"
          end
        end
      end
    end
  end

  def test_profile_legacy?
    inertia186 = players(:inertia186)
    resnullius = players(:resnullius)

    stub_mojang_sessions_server(inertia186.uuid.gsub(/-/, '')) do
      refute inertia186.profile_legacy?, 'did not expect profile legacy'
    end

    stub_mojang_sessions_server(resnullius.uuid.gsub(/-/, '')) do
      assert resnullius.profile_legacy?, 'expect profile legacy'
    end
  end

  def test_nick_history
    Player.all.find_each do |p|
      stub_nick_history(p.uuid.gsub(/-/, '')) do
        assert_equal 1, p.nick_history.length
      end
    end
  end

  def test_mmp_vote_status
    Preference.mmp_api_key = 'FAKE_API_KEY'

    Player.all.find_each do |p|
      stub_mmp_vote_history(p.nick) do
        refute_equal :unknown, p.mmp_vote_status, 'did not expect vote status :unknown'
      end
    end
  end

  def test_mmp_vote_claim!
    Preference.mmp_api_key = 'FAKE_API_KEY'

    Player.all.find_each do |p|
      options = {
        action: 'post',
        object: 'votes',
        element: 'claim',
        key: Preference.mmp_api_key,
        username: p.nick
      }
      stub_mmp_vote_claim(options) do
        assert p.mmp_vote_claim!, 'expect vote claim'
      end
    end
  end

  def test_last_pvp_loss_has_quote?
    assert players(:inertia186).last_pvp_loss_has_quote?, 'expect quote'
  end

  def test_last_pvp_win_has_quote?
    assert players(:inertia186).last_pvp_win_has_quote?, 'expect quote'
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
