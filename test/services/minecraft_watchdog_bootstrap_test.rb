require 'test_helper'

class MinecraftWatchdogBootstrapTest < ActiveSupport::TestCase
  FakeWorker = Struct.new(:job)

  class FakeResque
    attr_reader :enqueued

    def initialize(queue_size: 0, working: [], error: nil)
      @queue_size = queue_size
      @working = working
      @error = error
      @enqueued = []
    end

    def size(queue)
      raise error if error

      assert_queue queue
      queue_size
    end

    def working
      @working
    end

    def enqueue(worker)
      enqueued << worker
    end

  private
    attr_reader :error, :queue_size

    def assert_queue(queue)
      raise "Unexpected queue: #{queue}" unless queue == MinecraftWatchdog::QUEUE.to_s
    end
  end

  def test_enqueues_when_watchdog_is_absent
    resque = FakeResque.new

    result = MinecraftWatchdogBootstrap.call(resque: resque, logger: Logger.new(nil))

    assert_equal :enqueued, result
    assert_equal [MinecraftWatchdog], resque.enqueued
  end

  def test_does_not_enqueue_when_watchdog_is_pending
    resque = FakeResque.new(queue_size: 1)

    result = MinecraftWatchdogBootstrap.call(resque: resque, logger: Logger.new(nil))

    assert_equal :already_present, result
    assert_empty resque.enqueued
  end

  def test_does_not_enqueue_when_watchdog_is_running
    worker = FakeWorker.new({'payload' => {'class' => MinecraftWatchdog.name}})
    resque = FakeResque.new(working: [worker])

    result = MinecraftWatchdogBootstrap.call(resque: resque, logger: Logger.new(nil))

    assert_equal :already_present, result
    assert_empty resque.enqueued
  end

  def test_raises_cobblebot_error_when_redis_is_unavailable
    redis_error = Redis::CannotConnectError.new('connection refused')
    resque = FakeResque.new(error: redis_error)

    error = assert_raises CobbleBotError do
      MinecraftWatchdogBootstrap.call(resque: resque, logger: Logger.new(nil))
    end

    assert_equal MinecraftWatchdogBootstrap::REDIS_UNAVAILABLE_MESSAGE, error.message
    assert_empty resque.enqueued
  end
end
