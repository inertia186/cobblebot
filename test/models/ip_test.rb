require 'test_helper'

class IpTest < ActiveSupport::TestCase
  def test_origin
    ip = build_ip(address: '10.20.30.40', player: players(:Dinnerbone))
    ip.save!

    refute_nil ip.origin, 'expect origin'
  end

  def test_query_matches_address_origin_player_and_country_code
    ip = ips(:homeip)

    [ip.address, ip.origin, ip.player.nick, ip.cc].each do |query|
      assert_includes Ip.query(query), ip, "expected query match for #{query}"
    end
  end

  def test_country_code_counts_sort_in_both_directions
    build_ip(address: '10.0.0.1', player: players(:Dinnerbone), cc: 'CA').save!
    build_ip(address: '10.0.0.2', player: players(:resnullius), cc: 'CA').save!

    assert_equal [['US', 1], ['CA', 2]], Ip.cc_count(:asc)
    assert_equal [['CA', 2], ['US', 1]], Ip.cc_count(:desc)
    assert_equal({'CA' => 2, 'US' => 1}, Ip.cc_count(:unsorted))
  end

private
  def build_ip(attributes)
    Ip.new(attributes).tap { |ip| ip.no_cc_lookup = true }
  end
end
