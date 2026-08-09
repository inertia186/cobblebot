require 'test_helper'
require 'stringio'

class IrcCommandDispatcherTest < ActiveSupport::TestCase
  class InlineRailsExecutor
    attr_reader :wrap_count

    def initialize
      @wrap_count = 0
    end

    def wrap
      @wrap_count += 1
      yield
    end
  end

  class RecordingExecutor
    attr_reader :tasks

    def initialize(wait_result: true)
      @tasks = []
      @stopped = false
      @wait_result = wait_result
      @killed = false
    end

    def post(&task)
      return false if @stopped

      @tasks << task
      true
    end

    def shutdown
      @stopped = true
    end

    def wait_for_termination(*)
      @wait_result
    end

    def kill
      @stopped = true
      @killed = true
    end

    def killed?
      @killed
    end
  end

  def test_burst_never_exceeds_pool_or_queue_bounds
    release = Queue.new
    started = Queue.new
    mutex = Mutex.new
    active = 0
    maximum_active = 0
    dispatcher = IrcCommandDispatcher.new(
      rails_executor: InlineRailsExecutor.new,
      per_sender_limit: 100,
      global_limit: 100
    )

    statuses = 12.times.map do |index|
      dispatcher.submit("sender-#{index}") do
        mutex.synchronize do
          active += 1
          maximum_active = [maximum_active, active].max
        end
        started << true
        Timeout.timeout(5) { release.pop }
      ensure
        mutex.synchronize { active -= 1 }
      end
    end

    2.times do
      bounded_queue_pop(started, 'dispatcher workers did not start')
    end
    assert_equal 10, statuses.count(:accepted)
    assert_equal 2, statuses.count(:queue_full)
    assert_equal 2, maximum_active

    10.times { release << true }
    assert dispatcher.shutdown(timeout: 2)
    assert_equal 2, maximum_active
  ensure
    12.times { release << true } if release
    dispatcher&.shutdown(timeout: 1)
  end

  def test_per_sender_limit_uses_a_monotonic_sliding_window
    now = 100.0
    executor = RecordingExecutor.new
    dispatcher = IrcCommandDispatcher.new(
      executor: executor,
      clock: -> { now },
      rails_executor: InlineRailsExecutor.new,
      global_limit: 100
    )

    statuses = 4.times.map { dispatcher.submit('same-sender') {} }

    assert_equal [:accepted, :accepted, :accepted, :sender_rate_limited], statuses

    now += IrcCommandDispatcher::RATE_WINDOW + 0.1
    assert_equal :accepted, dispatcher.submit('same-sender') {}
  ensure
    dispatcher&.shutdown
  end

  def test_global_limit_applies_across_distinct_senders
    executor = RecordingExecutor.new
    dispatcher = IrcCommandDispatcher.new(
      executor: executor,
      clock: -> { 100.0 },
      rails_executor: InlineRailsExecutor.new,
      per_sender_limit: 100
    )

    statuses = 13.times.map do |index|
      dispatcher.submit("sender-#{index}") {}
    end

    assert_equal 12, statuses.count(:accepted)
    assert_equal :global_rate_limited, statuses.last
  ensure
    dispatcher&.shutdown
  end

  def test_handler_failure_is_logged_and_the_pool_processes_later_work
    logger_output = StringIO.new
    executor = Concurrent::ThreadPoolExecutor.new(
      min_threads: 1,
      max_threads: 1,
      max_queue: 2,
      fallback_policy: :discard
    )
    rails_executor = InlineRailsExecutor.new
    completed = Queue.new
    dispatcher = IrcCommandDispatcher.new(
      executor: executor,
      logger: Logger.new(logger_output),
      rails_executor: rails_executor,
      per_sender_limit: 100,
      global_limit: 100
    )

    assert_equal :accepted, dispatcher.submit('first') { raise 'handler failed' }
    assert_equal :accepted, dispatcher.submit('second') { completed << true }
    bounded_queue_pop(completed, 'dispatcher did not process later work')
    dispatcher.shutdown(timeout: 2)

    assert_includes logger_output.string, 'IRC command handler failed: RuntimeError'
    assert_equal 2, rails_executor.wrap_count
  ensure
    dispatcher&.shutdown(timeout: 1)
  end

  def test_shutdown_rejects_new_work
    dispatcher = IrcCommandDispatcher.new(
      executor: RecordingExecutor.new,
      rails_executor: InlineRailsExecutor.new
    )

    assert dispatcher.shutdown
    assert_equal :stopped, dispatcher.submit('sender') {}
  end

  def test_shutdown_kills_workers_that_do_not_finish_before_the_timeout
    executor = RecordingExecutor.new(wait_result: false)
    dispatcher = IrcCommandDispatcher.new(
      executor: executor,
      rails_executor: InlineRailsExecutor.new
    )

    assert dispatcher.shutdown(timeout: 0)
    assert executor.killed?
  end
end
