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

    result = PlayerAuthenticationBackfill.call(log_path: log.path, date: Date.new(2026, 8, 12))

    assert_equal 2, result.events
    assert_equal 1, result.created
    assert_equal 1, result.updated
    assert_equal Time.zone.local(2026, 8, 12, 9, 34, 22), Player.find_by_nick('NewPlayer').last_login_at
    assert_equal Time.zone.local(2026, 8, 12, 10, 2, 3), existing.reload.last_login_at

    second = PlayerAuthenticationBackfill.call(log_path: log.path, date: Date.new(2026, 8, 12))
    assert_equal 0, second.created
    assert_equal 2, second.updated
    assert_equal 1, Player.where(uuid: '6c96f4b2-03de-47f4-bc0a-b9cad83d84b3').count
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
end
