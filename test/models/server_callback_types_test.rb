require 'test_helper'

class ServerCallbackTypesTest < ActiveSupport::TestCase
  AUTHENTICATED = '[12:00:00] [User Authenticator #1/INFO]: UUID of player inertia186 is %s'
  ACHIEVEMENT = '[12:00:00] [Server thread/INFO]: inertia186 has just earned the achievement [Taking Inventory]'
  DEATH = '[12:00:00] [Server thread/INFO]: inertia186 fell from a high place'
  RUNNING_BEHIND = "[12:00:00] [Server thread/WARN]: Can't keep up! Did the system time change, or is the server overloaded? Running 1234ms behind, skipping 24 tick(s)"

  def test_player_authenticated_detection_and_entry
    line = format(AUTHENTICATED, players(:inertia186).uuid)

    assert ServerCallback::PlayerAuthenticated.for_handling(line)
    assert_equal ['inertia186', "UUID of player inertia186 is #{players(:inertia186).uuid}", line, {source: :test}],
      ServerCallback::PlayerAuthenticated.entry(line, source: :test)
  end

  def test_new_player_authenticated_requires_a_recent_player
    player = players(:inertia186)
    line = format(AUTHENTICATED, player.uuid)
    player.update_column(:created_at, Time.current)
    assert ServerCallback::NewPlayerAuthenticated.for_handling(line)

    player.update_column(:created_at, 2.days.ago)
    refute ServerCallback::NewPlayerAuthenticated.for_handling(line)
    refute ServerCallback::NewPlayerAuthenticated.for_handling('ordinary line')
  end

  def test_achievement_detection_and_entry
    assert ServerCallback::AchievementAnnouncement.for_handling(ACHIEVEMENT)
    assert_equal ['inertia186', 'inertia186 has just earned the achievement [Taking Inventory]', ACHIEVEMENT, {}],
      ServerCallback::AchievementAnnouncement.entry(ACHIEVEMENT, {})
  end

  def test_death_detection_excludes_player_chat
    assert ServerCallback::DeathAnnouncement.for_handling(DEATH)
    assert_equal ['inertia186', 'inertia186 fell from a high place', DEATH, {}],
      ServerCallback::DeathAnnouncement.entry(DEATH, {})

    chat = '[12:00:00] [Server thread/INFO]: <inertia186> Dinnerbone was killed by zombie'
    refute ServerCallback::DeathAnnouncement.for_handling(chat)
  end

  def test_running_behind_and_any_entry_parsing
    assert ServerCallback::RunningBehind.for_handling(RUNNING_BEHIND)
    assert_equal [nil, "Can't keep up! Did the system time change, or is the server overloaded? Running 1234ms behind, skipping 24 tick(s)", RUNNING_BEHIND, {}],
      ServerCallback::RunningBehind.entry(RUNNING_BEHIND, {})

    assert ServerCallback::AnyEntry.for_handling(DEATH)
    assert_equal [nil, 'inertia186 fell from a high place', DEATH, {}],
      ServerCallback::AnyEntry.entry(DEATH, {})
  end
end
