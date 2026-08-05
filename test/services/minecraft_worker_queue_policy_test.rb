require 'test_helper'
require 'stringio'

class MinecraftWorkerQueuePolicyTest < ActiveSupport::TestCase
  class FakeResque
    attr_reader :jobs, :enqueue_calls, :dequeue_calls, :size_calls

    def initialize
      @jobs = Hash.new { |hash, queue| hash[queue] = [] }
      @enqueue_calls = []
      @dequeue_calls = []
      @size_calls = []
    end

    def seed(worker_class, options = {})
      @jobs[worker_class::QUEUE] << [worker_class, options]
    end

    def seed_queue(queue, payload)
      @jobs[queue.to_sym] << payload
    end

    def size(queue)
      queue = queue.to_sym
      @size_calls << queue
      @jobs[queue].size
    end

    def enqueue(worker_class, options)
      @enqueue_calls << [worker_class, options]
      seed(worker_class, options)
    end

    def dequeue(worker_class)
      @dequeue_calls << worker_class
      @jobs[worker_class::QUEUE].delete_if { |job| job.first == worker_class }
    end
  end

  def setup
    @resque = FakeResque.new
    @log_output = StringIO.new
    @logger = Logger.new(@log_output)
    @server_log = '/minecraft/logs/latest.log'
  end

  def test_empty_enabled_queues_enqueue_canonical_standbys_once
    expected = {
      MinecraftServerLogMonitor::QUEUE => :enqueued,
      IrcBot::QUEUE => :enqueued
    }

    assert_equal expected, call_policy
    assert_equal [
      [MinecraftServerLogMonitor, {server_log: @server_log, max_ticks: 1200}],
      [IrcBot, {start_irc_bot: true}]
    ], @resque.enqueue_calls

    expected = {
      MinecraftServerLogMonitor::QUEUE => :already_present,
      IrcBot::QUEUE => :already_present
    }
    assert_equal expected, call_policy
    assert_equal 2, @resque.enqueue_calls.size
    assert_includes @log_output.string, 'result=already_present'
  end

  def test_exactly_one_pending_job_is_left_unchanged
    @resque.seed(MinecraftServerLogMonitor, custom: 'payload')
    @resque.seed(IrcBot, custom: 'payload')

    assert_equal({
      MinecraftServerLogMonitor::QUEUE => :already_present,
      IrcBot::QUEUE => :already_present
    }, call_policy)
    assert_empty @resque.enqueue_calls
    assert_empty @resque.dequeue_calls
  end

  def test_excess_pending_jobs_are_replaced_with_one_canonical_job
    2.times { @resque.seed(MinecraftServerLogMonitor, stale: true) }
    3.times { @resque.seed(IrcBot, stale: true) }

    assert_equal({
      MinecraftServerLogMonitor::QUEUE => :reset,
      IrcBot::QUEUE => :reset
    }, call_policy)
    assert_equal [MinecraftServerLogMonitor, IrcBot], @resque.dequeue_calls
    assert_equal [[MinecraftServerLogMonitor, {server_log: @server_log, max_ticks: 1200}]],
      @resque.jobs[MinecraftServerLogMonitor::QUEUE]
    assert_equal [[IrcBot, {start_irc_bot: true}]], @resque.jobs[IrcBot::QUEUE]
    assert_includes @log_output.string, 'result=reset'
  end

  def test_disabled_irc_clears_pending_jobs_without_enqueuing
    @resque.seed(IrcBot, start_irc_bot: true)

    assert_equal :cleared, call_policy(irc_enabled: false).fetch(IrcBot::QUEUE)
    assert_empty @resque.jobs[IrcBot::QUEUE]
    assert_includes @resque.dequeue_calls, IrcBot
    assert_includes @log_output.string, 'queue=irc_bot result=cleared pending=1'

    assert_equal :disabled, call_policy(irc_enabled: false).fetch(IrcBot::QUEUE)
    assert_equal 1, @resque.dequeue_calls.count(IrcBot)
  end

  def test_unmanaged_queues_are_not_inspected_or_changed
    unmanaged_payload = ['OtherWorker', {important: true}]
    @resque.seed_queue(:unmanaged, unmanaged_payload)

    call_policy

    assert_equal [unmanaged_payload], @resque.jobs[:unmanaged]
    refute_includes @resque.size_calls, :unmanaged
  end

  def test_results_are_logged_for_each_managed_queue
    call_policy(irc_enabled: false)

    output = @log_output.string
    assert_includes output, 'queue=minecraft_server_log_monitor result=enqueued pending=0'
    assert_includes output, 'queue=irc_bot result=disabled pending=0'
  end

  def test_backend_errors_propagate
    error = RuntimeError.new('backend unavailable')
    @resque.define_singleton_method(:size) { |_queue| raise error }

    raised = assert_raises(RuntimeError) { call_policy }
    assert_same error, raised
  end

private
  def call_policy(irc_enabled: true)
    MinecraftWorkerQueuePolicy.call(
      resque: @resque,
      logger: @logger,
      irc_enabled: irc_enabled,
      server_log: @server_log
    )
  end
end
