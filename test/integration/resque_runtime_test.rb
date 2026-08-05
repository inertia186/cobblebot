require 'test_helper'
require 'securerandom'

class ResqueRuntimeTest < ActiveSupport::TestCase
  class UnmanagedWorker
    @queue = :unmanaged_runtime_test

    def self.perform
    end
  end

  def setup
    skip 'Set REDIS_INTEGRATION=1 to run the isolated Redis integration test.' unless ENV['REDIS_INTEGRATION'] == '1'

    @original_data_store = Resque.redis
    namespace = "cobblebot-test-#{Process.pid}-#{SecureRandom.hex(6)}"
    env = {
      'COBBLEBOT_REDIS_URL' => ENV['COBBLEBOT_REDIS_URL'],
      'COBBLEBOT_RESQUE_NAMESPACE' => namespace
    }.reject { |_key, value| value.to_s.empty? }
    @namespaced_redis = ResqueConfiguration.load(environment: 'test', env: env).apply
  end

  def teardown
    return unless @namespaced_redis

    keys = @namespaced_redis.keys('*')
    @namespaced_redis.del(*keys) if keys.any?
    Resque.redis = @original_data_store
  end

  def test_watchdog_bootstrap_serializes_once_and_is_idempotent
    assert_equal :enqueued, MinecraftWatchdogBootstrap.call
    assert_equal :already_present, MinecraftWatchdogBootstrap.call
    assert_equal 1, Resque.size(MinecraftWatchdog::QUEUE)

    payload = Resque.peek(MinecraftWatchdog::QUEUE, 0)
    assert_equal MinecraftWatchdog.name, payload.fetch('class')
    assert_equal [], payload.fetch('args')
  end

  def test_worker_queue_policy_resets_managed_payloads_and_preserves_unmanaged_work
    2.times { Resque.enqueue(MinecraftServerLogMonitor, stale: true) }
    2.times { Resque.enqueue(IrcBot, start_irc_bot: true) }
    Resque.enqueue(UnmanagedWorker)

    results = MinecraftWorkerQueuePolicy.call(
      irc_enabled: false,
      server_log: '/minecraft/logs/latest.log'
    )

    assert_equal :reset, results.fetch(MinecraftServerLogMonitor::QUEUE)
    assert_equal :cleared, results.fetch(IrcBot::QUEUE)
    assert_equal 1, Resque.size(MinecraftServerLogMonitor::QUEUE)
    assert_equal 0, Resque.size(IrcBot::QUEUE)
    assert_equal 1, Resque.size(:unmanaged_runtime_test)

    payload = Resque.peek(MinecraftServerLogMonitor::QUEUE, 0)
    assert_equal MinecraftServerLogMonitor.name, payload.fetch('class')
    assert_equal [{
      'server_log' => '/minecraft/logs/latest.log',
      'max_ticks' => MinecraftWorkerQueuePolicy::MONITOR_MAX_TICKS
    }], payload.fetch('args')

    assert_equal :already_present, MinecraftWorkerQueuePolicy.call(
      irc_enabled: false,
      server_log: '/minecraft/logs/latest.log'
    ).fetch(MinecraftServerLogMonitor::QUEUE)
    assert_equal 1, Resque.size(:unmanaged_runtime_test)
  end
end
