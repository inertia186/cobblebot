require 'test_helper'
require 'tempfile'

class PlayerAuthenticationBackfillTest < ActiveSupport::TestCase
  def test_backfills_exact_authentication_lines_idempotently
    existing = players(:inertia186)
    existing.update!(last_login_at: nil)

    log = Tempfile.new('authentication-backfill')
    log.write <<~LOG
      [09:00:00] [Server thread/INFO]: ordinary message
      [09:34:22] [User Authenticator #11/INFO]: UUID of player NewPlayer is 6c96f4b2-03de-47f4-bc0a-b9cad83d84b3
      [10:02:03] [User Authenticator #12/INFO]: UUID of player inertia186 is #{existing.uuid}
    LOG
    log.close
    stamp = Time.find_zone!('America/Los_Angeles').local(2026, 8, 12, 12)
    File.utime(stamp.to_time, stamp.to_time, log.path)

    result = PlayerAuthenticationBackfill.call(log_path: log.path, date: Date.new(2026, 8, 12))

    assert_equal 2, result.events
    assert_equal 1, result.created
    assert_equal 1, result.updated
    zone = Time.find_zone!('America/Los_Angeles')
    assert_equal zone.local(2026, 8, 12, 9, 34, 22), Player.find_by_nick('NewPlayer').last_login_at
    assert_equal zone.local(2026, 8, 12, 10, 2, 3), existing.reload.last_login_at

    second = PlayerAuthenticationBackfill.call(log_path: log.path, date: Date.new(2026, 8, 12))
    assert_equal 0, second.created
    assert_equal 2, second.updated
    assert_equal 1, Player.where(uuid: '6c96f4b2-03de-47f4-bc0a-b9cad83d84b3').count
  ensure
    log&.unlink
  end

  def test_rejects_stale_log_before_writing
    with_log(authentication_line('NewPlayer', NEW_UUID, '09:00:00'), day: 11) do |path|
      assert_no_difference 'Player.count' do
        assert_raises(ArgumentError) { backfill(path) }
      end
    end
  end

  def test_rejects_midnight_rollover_before_writing
    with_log(authentication_line('NewPlayer', NEW_UUID, '23:59:00') +
             "[00:01:00] [Server thread/INFO]: ordinary message\n") do |path|
      assert_no_difference 'Player.count' do
        assert_raises(ArgumentError) { backfill(path) }
      end
    end
  end

  def test_rejects_decreasing_clocks_before_writing
    with_log(authentication_line('NewPlayer', NEW_UUID, '10:00:00') +
             "[09:00:00] [Server thread/INFO]: ordinary message\n") do |path|
      assert_no_difference 'Player.count' do
        assert_raises(ArgumentError) { backfill(path) }
      end
    end
  end

  def test_rejects_entries_later_than_log_modification
    with_log(authentication_line('NewPlayer', NEW_UUID, '13:00:00')) do |path|
      assert_raises(ArgumentError) { backfill(path) }
    end
  end

  def test_rejects_future_log
    travel_to Time.find_zone!('America/Los_Angeles').local(2026, 8, 12, 8) do
      with_log(authentication_line('NewPlayer', NEW_UUID, '09:00:00')) do |path|
        assert_raises(ArgumentError) { backfill(path) }
      end
    end
  end

  def test_failed_existing_player_update_rolls_back_earlier_creation
    existing = players(:inertia186)
    original = existing.attributes
    with_log(authentication_line('NewPlayer', NEW_UUID, '09:00:00') +
             authentication_line(players(:Dinnerbone).nick, existing.uuid, '10:00:00')) do |path|
      assert_no_difference 'Player.count' do
        assert_raises(ActiveRecord::RecordInvalid) { backfill(path) }
      end
      assert_equal original, existing.reload.attributes
      assert_nil Player.find_by_uuid(NEW_UUID)
    end
  end

  def test_failed_new_player_save_rolls_back
    with_log(authentication_line(players(:Dinnerbone).nick, NEW_UUID, '09:00:00')) do |path|
      assert_no_difference 'Player.count' do
        assert_raises(ActiveRecord::RecordInvalid) { backfill(path) }
      end
    end
  end

  def test_rejects_invalid_clock
    with_log(authentication_line('NewPlayer', NEW_UUID, '25:00:00')) do |path|
      assert_raises(ArgumentError) { backfill(path) }
    end
  end

  def test_rejects_dst_ambiguous_clock
    log = Tempfile.new('authentication-backfill')
    log.write(authentication_line('NewPlayer', NEW_UUID, '01:30:00'))
    log.close
    stamp = Time.find_zone!('America/Los_Angeles').local(2025, 11, 2, 12).to_time
    File.utime(stamp, stamp, log.path)
    assert_raises(ArgumentError) do
      PlayerAuthenticationBackfill.call(log_path: log.path, date: Date.new(2025, 11, 2))
    end
  ensure
    log&.unlink
  end

  def test_rejects_symlinked_logs
    log = Tempfile.new('authentication-backfill-target')
    link = "#{log.path}.link"
    File.symlink(log.path, link)

    error = assert_raises(ArgumentError) do
      PlayerAuthenticationBackfill.call(log_path: link, date: Date.new(2026, 8, 12))
    end

    assert_equal 'authentication log must not be a symlink', error.message
  ensure
    File.unlink(link) if link && File.symlink?(link)
    log&.unlink
  end

  private

  NEW_UUID = '6c96f4b2-03de-47f4-bc0a-b9cad83d84b3'

  def authentication_line(nick, uuid, clock)
    "[#{clock}] [User Authenticator #11/INFO]: UUID of player #{nick} is #{uuid}\n"
  end

  def backfill(path)
    PlayerAuthenticationBackfill.call(log_path: path, date: Date.new(2026, 8, 12))
  end

  def with_log(contents, day: 12)
    log = Tempfile.new('authentication-backfill')
    log.write(contents)
    log.close
    stamp = Time.find_zone!('America/Los_Angeles').local(2026, 8, day, 12)
    File.utime(stamp.to_time, stamp.to_time, log.path)
    yield log.path
  ensure
    log&.unlink
  end
end
