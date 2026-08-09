require 'test_helper'

class BannedPlayerTest < ActiveSupport::TestCase
  def test_find_matches_uuid_or_nick_and_rejects_unknown_identifiers
    data = [
      ban('first-uuid', 'First'),
      ban('second-uuid', 'Second')
    ]

    BannedPlayer.stub(:banned_players_data, data) do
      assert_equal 'second-uuid', BannedPlayer.find(uuid: 'second-uuid').uuid
      assert_equal 'second-uuid', BannedPlayer.find(nick: 'Second').uuid
      assert_nil BannedPlayer.find(uuid: 'missing')
      assert_nil BannedPlayer.find(nick: 'Missing')
      assert_nil BannedPlayer.find
    end
  end

private
  def ban(uuid, nick)
    {
      'uuid' => uuid, 'name' => nick, 'source' => 'Server', 'reason' => 'test',
      'expires' => 'forever', 'created' => '2026-08-09 03:00:00 +0000'
    }
  end
end
