require 'test_helper'

class ServerCallbackExecutionLockTest < ActiveSupport::TestCase
  Callback = Struct.new(:id)

  class RecordingRawConnection
    attr_reader :calls

    def initialize
      @calls = []
    end

    def exec_params(sql, binds)
      @calls << [sql, binds]
    end
  end

  class RecordingConnection
    attr_reader :raw_connection

    def initialize
      @raw_connection = RecordingRawConnection.new
    end
  end

  class RecordingPool
    attr_reader :connection

    def initialize
      @connection = RecordingConnection.new
    end

    def with_connection
      yield connection
    end
  end

  def test_postgresql_lock_supports_bigint_callback_ids_with_bound_keys
    pool = RecordingPool.new
    callback_id = 2**31
    executed = false

    ServerCallbackExecutionLock.synchronize(
      Callback.new(callback_id),
      adapter_name: 'postgresql',
      connection_pool: pool
    ) { executed = true }

    assert executed
    assert_equal [
      'SELECT pg_advisory_lock($1::bigint)',
      'SELECT pg_advisory_unlock($1::bigint)'
    ], pool.connection.raw_connection.calls.map(&:first)
    lock_keys = pool.connection.raw_connection.calls.map { |_sql, binds| binds.fetch(0) }
    assert_equal 1, lock_keys.uniq.length
    assert_operator lock_keys.first, :>=, -(2**63)
    assert_operator lock_keys.first, :<, 2**63
    refute_includes pool.connection.raw_connection.calls.map(&:first).join, callback_id.to_s
  end

  def test_sqlite_file_lock_serializes_threads_and_releases_afterward
    lock_root = Rails.root.join('tmp/test-callback-locks', SecureRandom.hex(6))
    ready = Queue.new
    start = Queue.new
    attempted = Queue.new
    entered = Queue.new
    release = Queue.new
    callback = Callback.new(42)

    threads = 2.times.map do |index|
      Thread.new do
        ready << true
        Timeout.timeout(5) { start.pop }
        attempted << true
        ServerCallbackExecutionLock.synchronize(
          callback,
          adapter_name: 'sqlite3',
          connection_pool: nil,
          lock_root: lock_root
        ) do
          entered << index
          Timeout.timeout(5) { release.pop }
        end
      end
    end

    2.times { bounded_queue_pop(ready, 'lock worker did not initialize') }
    2.times { start << true }
    2.times { bounded_queue_pop(attempted, 'lock worker did not attempt entry') }
    first = bounded_queue_pop(entered, 'no lock worker entered')
    assert_raises(Timeout::Error) do
      Timeout.timeout(0.1) { entered.pop }
    end
    release << true
    second = bounded_queue_pop(entered, 'second lock worker never entered')
    release << true
    join_threads(threads, 'lock worker did not finish')

    refute_equal first, second
    assert File.exist?(lock_root.join('server_callback_42.lock'))
  ensure
    2.times { start << true } if start
    2.times { release << true } if release
    threads&.each { |thread| thread.kill if thread.alive? }
    FileUtils.rm_rf(lock_root) if lock_root
  end

  def test_unknown_adapter_is_rejected
    error = assert_raises(NotImplementedError) do
      ServerCallbackExecutionLock.synchronize(
        Callback.new(1),
        adapter_name: 'unknown',
        connection_pool: nil,
        lock_root: Rails.root.join('tmp')
      ) { flunk 'must not execute' }
    end

    assert_includes error.message, 'unknown'
  end
end
