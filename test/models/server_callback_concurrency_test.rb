require 'test_helper'

class ServerCallbackConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def setup
    @callback = ServerCallback::ServerEntry.create!(
      name: "Atomic Callback #{SecureRandom.hex(6)}",
      pattern: '/atomic callback/',
      command: 'true',
      cooldown: '+1 minute',
      enabled: true
    )
  end

  def teardown
    @callback&.destroy!
  end

  def test_concurrent_matches_execute_once_during_cooldown
    threads = nil
    ready = Queue.new
    start = Queue.new
    results = Queue.new
    executions = Queue.new
    executor = lambda do |*_arguments|
      executions << true
      sleep 0.1
      :executed
    end

    ServerCommand.stub(:eval_command, executor) do
      threads = 2.times.map do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            ready << true
            Timeout.timeout(5) { start.pop }
            callback = ServerCallback.find(@callback.id)
            results << callback.handle_entry(
              nil,
              'atomic callback',
              'the matching log line'
            )
          end
        end
      end
      2.times do
        bounded_queue_pop(ready, 'callback worker did not acquire a connection')
      end
      2.times { start << true }
      join_threads(threads, 'callback worker did not finish')
    end

    assert_equal 1, executions.size
    callback_results = 2.times.map do
      bounded_queue_pop(results, 'callback worker did not publish a result')
    end
    assert_equal [nil, true], callback_results.sort_by(&:to_s)
    assert @callback.reload.ran_at
    assert_equal 'the matching log line', @callback.last_match
  ensure
    threads&.each { |thread| thread.kill if thread.alive? }
  end

  def test_terminated_execution_rolls_back_and_can_retry
    terminating = lambda do |*_arguments|
      raise Resque::TermException.new('TERM')
    end

    ServerCommand.stub(:eval_command, terminating) do
      assert_raises(Resque::TermException) do
        @callback.handle_entry(nil, 'atomic callback', 'interrupted line')
      end
    end

    refute @callback.reload.ran?
    assert_nil @callback.last_match

    ServerCommand.stub(:eval_command, :retried) do
      assert @callback.handle_entry(nil, 'atomic callback', 'retry line')
    end

    assert @callback.reload.ran?
    assert_equal 'retry line', @callback.last_match
  end

  def test_normal_command_failure_records_cooldown_and_blocks_a_duplicate
    failure = ->(*_arguments) { raise 'command failed' }

    ServerCommand.stub(:eval_command, failure) do
      assert @callback.handle_entry(nil, 'atomic callback', 'failed line')
    end

    assert @callback.reload.ran?
    assert @callback.error_flag?
    assert_includes @callback.last_command_output, 'Unable to evaluate command'

    ServerCommand.stub(:eval_command, :unexpected_retry) do
      assert_nil @callback.handle_entry(nil, 'atomic callback', 'duplicate line')
    end
    assert_equal 'failed line', @callback.reload.last_match
  end

  def test_callback_code_does_not_run_inside_a_database_transaction
    transaction_open = nil
    executor = lambda do |*_arguments|
      transaction_open = ActiveRecord::Base.connection.transaction_open?
      :executed
    end

    ServerCommand.stub(:eval_command, executor) do
      assert @callback.handle_entry(nil, 'atomic callback', 'matching line')
    end

    assert_equal false, transaction_open
  end
end
