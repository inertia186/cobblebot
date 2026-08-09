require 'test_helper'

class BannedIpTest < ActiveSupport::TestCase
  def test_find_returns_the_matching_ip_and_nil_for_an_unknown_ip
    data = [
      ban('203.0.113.1'),
      ban('203.0.113.2')
    ]

    BannedIp.stub(:banned_ips_data, data) do
      assert_equal '203.0.113.2', BannedIp.find(ip: '203.0.113.2').ip
      assert_nil BannedIp.find(ip: '203.0.113.99')
      assert_nil BannedIp.find
    end
  end

private
  def ban(ip)
    {
      'ip' => ip, 'source' => 'Server', 'reason' => 'test',
      'expires' => 'forever', 'created' => '2026-08-09 03:00:00 +0000'
    }
  end
end
