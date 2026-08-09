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

  def test_database_rejects_duplicate_addresses_for_the_same_player
    ip = build_ip(address: '203.0.113.10', player: players(:Dinnerbone))
    ip.save!

    assert_raises ActiveRecord::RecordNotUnique do
      Ip.insert_all!([{
        address: ip.address,
        player_id: ip.player_id,
        origin: ip.origin,
        created_at: ip.created_at
      }])
    end
  end

  def test_address_must_be_a_valid_ip_without_running_a_lookup
    Ip.stub(:update_cc, ->(*) { flunk 'invalid addresses must not be looked up' }) do
      ip = Ip.new(address: '127.0.0.1; touch unsafe', player: players(:Dinnerbone))

      refute ip.valid?
      assert_includes ip.errors[:address], 'must be a valid IP address'
    end
  end

  def test_country_lookup_fallback_passes_the_address_as_one_argument
    Preference.db_ip_api_key = nil
    captured_arguments = nil
    success = Struct.new(:success?).new(true)

    Open3.stub(:capture3, ->(*arguments) {
      captured_arguments = arguments
      ["Country: US United States\n", '', success]
    }) do
      result = Ip.send(:update_cc, '203.0.113.9')

      assert_equal ['ip2cc', '203.0.113.9'], captured_arguments
      assert_equal({ country: 'US', state: nil, city: nil }, result)
    end
  end

  def test_country_lookup_uses_the_db_ip_v2_https_api
    Preference.db_ip_api_key = 'FAKE_API_KEY'
    request = stub_request(
      :get,
      'https://api.db-ip.com/v2/FAKE_API_KEY/203.0.113.9'
    ).to_return(
      status: 200,
      body: {
        countryCode: 'US', stateProv: 'California', city: 'Los Angeles'
      }.to_json
    )

    result = Ip.send(:update_cc, '203.0.113.9')

    assert_equal({ country: 'US', state: 'California', city: 'Los Angeles' }, result)
    assert_requested request
  end

private
  def build_ip(attributes)
    Ip.new(attributes).tap { |ip| ip.no_cc_lookup = true }
  end
end
