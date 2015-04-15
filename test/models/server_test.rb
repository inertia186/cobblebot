require 'test_helper'

class ServerTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_banned_players
    assert Server.banned_players, "expect banned players json"
  end

  def test_banned_ips
    assert Server.banned_ips, "expect banned ips json"
  end

  def test_ops
    assert Server.ops, "expect ops json"
  end

  def test_whitelist
    assert Server.whitelist, "expect whitelist json"
  end
end
