require 'test_helper'
require 'securerandom'
require 'resque-scheduler'

class ResqueRuntimeTest < ActionDispatch::IntegrationTest
  class UnmanagedWorker
    @queue = :unmanaged_runtime_test

    def self.perform
    end
  end

  def setup
    @original_data_store = Resque.redis
    namespace = "cobblebot-test-#{Process.pid}-#{SecureRandom.hex(6)}"
    env = {
      'COBBLEBOT_REDIS_URL' => ENV['COBBLEBOT_REDIS_URL'],
      'COBBLEBOT_RESQUE_NAMESPACE' => namespace
    }.reject { |_key, value| value.to_s.empty? }
    @namespaced_redis = ResqueConfiguration.load(environment: 'test', env: env).apply
    @namespaced_redis.ping
  rescue Redis::BaseConnectionError, SystemCallError, SocketError => error
    flunk "Redis is required for the default test suite: #{error.class}"
  end

  def teardown
    return unless @namespaced_redis

    keys = @namespaced_redis.keys('*')
    @namespaced_redis.del(*keys) if keys.any?
    Resque.redis = @original_data_store
  end

  def test_watchdog_bootstrap_serializes_once_and_is_idempotent
    assert_equal 3, @namespaced_redis.redis.call('HELLO').fetch('proto')
    assert_instance_of Resque::DataStore, Resque.redis
    assert_equal :enqueued, MinecraftWatchdogBootstrap.call
    assert_equal :already_present, MinecraftWatchdogBootstrap.call
    assert_equal 1, Resque.size(MinecraftWatchdog::QUEUE)

    payload = Resque.peek(MinecraftWatchdog::QUEUE, 0)
    assert_equal MinecraftWatchdog.name, payload.fetch('class')
    assert_equal [], payload.fetch('args')

    schedule = YAML.safe_load(File.read(Rails.root.join('config/resque_schedule.yml')))
    Resque.schedule = schedule
    assert_equal '*/5 * * * *', Resque.schedule.fetch('MinecraftWatchdog').fetch('cron')
    assert_equal 'MinecraftWatchdogDispatcher',
      Resque.schedule.fetch('MinecraftWatchdog').fetch('class')
    assert_equal 'minecraft_watchdog',
      Resque.schedule.fetch('MinecraftWatchdog').fetch('queue')

    worker = Resque::Worker.new(MinecraftWatchdog::QUEUE)
    Resque.redis.register_worker(worker)
    job = worker.reserve

    assert_equal MinecraftWatchdog.name, job.payload.fetch('class')
    assert_equal 0, Resque.size(MinecraftWatchdog::QUEUE)
    assert_equal MinecraftWatchdog.name,
      worker.job.fetch('payload').fetch('class'),
      'reservation must publish working state in the same Redis operation as the pop'

    assert_equal :already_present, MinecraftWatchdogBootstrap.call
    Resque.enqueue(MinecraftWatchdog)
    assert_equal :already_present, MinecraftWatchdogBootstrap.call
    assert_equal 0, Resque.size(MinecraftWatchdog::QUEUE),
      'a running watchdog must atomically suppress a concurrently queued duplicate'

    get '/admin/resque/'
    assert_response :unauthorized

    authorization = ActionController::HttpAuthentication::Basic.encode_credentials(
      'admin',
      Preference.web_admin_password
    )
    get '/admin/resque/', headers: {'HTTP_AUTHORIZATION' => authorization}
    assert_redirected_to '/admin/resque/overview'
    follow_redirect! headers: {'HTTP_AUTHORIZATION' => authorization}
    assert_response :success
  ensure
    worker&.unregister_worker
  end

  def test_worker_queue_policy_resets_managed_payloads_and_preserves_unmanaged_work
    legacy_queue = 'resque_1_compatible'
    legacy_payload = {'class' => UnmanagedWorker.name, 'args' => [{'legacy' => true}]}
    @namespaced_redis.sadd(:queues, legacy_queue)
    @namespaced_redis.rpush("queue:#{legacy_queue}", MultiJSON.generate(legacy_payload))

    assert_equal legacy_payload, Resque.peek(legacy_queue, 0)

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

    serialized_payload = @namespaced_redis.lindex(
      "queue:#{MinecraftServerLogMonitor::QUEUE}",
      0
    )
    assert_equal payload, MultiJSON.parse(serialized_payload)

    assert_equal :already_present, MinecraftWorkerQueuePolicy.call(
      irc_enabled: false,
      server_log: '/minecraft/logs/latest.log'
    ).fetch(MinecraftServerLogMonitor::QUEUE)
    assert_equal 1, Resque.size(:unmanaged_runtime_test)
  end

  def test_concurrent_bootstrap_and_policy_calls_leave_one_canonical_job
    bootstrap_results = run_concurrently(8) do
      MinecraftWatchdogBootstrap.call
    end

    assert_equal 1, bootstrap_results.count(:enqueued)
    assert_equal 7, bootstrap_results.count(:already_present)
    assert_equal 1, Resque.size(MinecraftWatchdog::QUEUE)

    policy_results = run_concurrently(8) do
      MinecraftWorkerQueuePolicy.call(
        irc_enabled: false,
        server_log: '/minecraft/logs/latest.log'
      ).fetch(MinecraftServerLogMonitor::QUEUE)
    end

    assert_equal 1, policy_results.count(:enqueued)
    assert_equal 7, policy_results.count(:already_present)
    assert_equal 1, Resque.size(MinecraftServerLogMonitor::QUEUE)
  end

  def test_atomic_reset_preserves_unrelated_payload_order
    queue = MinecraftServerLogMonitor::QUEUE
    before = {'class' => UnmanagedWorker.name, 'args' => [{'position' => 'before'}]}
    after = {'class' => UnmanagedWorker.name, 'args' => [{'position' => 'after'}]}
    Resque.push(queue, before)
    Resque.enqueue(MinecraftServerLogMonitor, stale: 1)
    Resque.enqueue(MinecraftServerLogMonitor, stale: 2)
    Resque.push(queue, after)

    result = ResqueQueueReconciler.call(
      worker_class: MinecraftServerLogMonitor,
      args: [{server_log: '/canonical/latest.log', max_ticks: 1200}]
    )

    assert_equal :reset, result.status
    assert_equal 2, result.pending
    assert_equal [
      before,
      {
        'class' => MinecraftServerLogMonitor.name,
        'args' => [{
          'server_log' => '/canonical/latest.log',
          'max_ticks' => 1200
        }]
      },
      after
    ], Resque.peek(queue, 0, Resque.size(queue))
  end

  def test_single_stale_payload_is_replaced_with_the_canonical_payload
    Resque.enqueue(MinecraftServerLogMonitor, server_log: '/stale.log', max_ticks: 1)

    result = ResqueQueueReconciler.call(
      worker_class: MinecraftServerLogMonitor,
      args: [{server_log: '/current.log', max_ticks: 1200}]
    )

    assert_equal :reset, result.status
    assert_equal 1, result.pending
    assert_equal [{
      'server_log' => '/current.log',
      'max_ticks' => 1200
    }], Resque.peek(MinecraftServerLogMonitor::QUEUE, 0).fetch('args')
  end

  def test_malformed_payload_is_not_lost_when_atomic_reservation_rejects_it
    queue = MinecraftWatchdog::QUEUE
    @namespaced_redis.sadd('queues', queue)
    @namespaced_redis.rpush("queue:#{queue}", '{malformed')
    worker = Resque::Worker.new(queue)
    Resque.redis.register_worker(worker)

    assert_raises(Redis::CommandError) { worker.reserve }
    assert_equal '{malformed', @namespaced_redis.lindex("queue:#{queue}", 0)
    assert_nil worker.job.fetch('payload', nil)
  ensure
    worker&.unregister_worker
  end

private
  def run_concurrently(count)
    ready = Queue.new
    start = Queue.new
    results = Queue.new
    threads = count.times.map do
      Thread.new do
        ready << true
        start.pop
        results << yield
      end
    end
    count.times { ready.pop }
    count.times { start << true }
    threads.each(&:join)
    count.times.map { results.pop }
  end

end
