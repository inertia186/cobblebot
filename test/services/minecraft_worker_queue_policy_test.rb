require 'test_helper'
require Rails.root.join('test/support/queue_reconciler_recorder')
require 'stringio'

class MinecraftWorkerQueuePolicyTest < ActiveSupport::TestCase
  def setup
    @resque = Object.new
    @log_output = StringIO.new
    @logger = Logger.new(@log_output)
    @server_log = '/minecraft/logs/latest.log'
  end

  def test_reconciles_both_enabled_workers_with_canonical_arguments
    reconciler = recorder(
      MinecraftServerLogMonitor => result(:enqueued, 0),
      IrcBot => result(:already_present, 1)
    )

    assert_equal({
      MinecraftServerLogMonitor::QUEUE => :enqueued,
      IrcBot::QUEUE => :already_present
    }, call_policy(reconciler))
    assert_equal [
      {
        resque: @resque,
        worker_class: MinecraftServerLogMonitor,
        enabled: true,
        args: [{server_log: @server_log, max_ticks: 1200}]
      },
      {
        resque: @resque,
        worker_class: IrcBot,
        enabled: true,
        args: [{start_irc_bot: true}]
      }
    ], reconciler.calls
    assert_includes @log_output.string,
      'queue=minecraft_server_log_monitor result=enqueued pending=0'
    assert_includes @log_output.string,
      'queue=irc_bot result=already_present pending=1'
  end

  def test_passes_disabled_irc_through_and_returns_reconciler_statuses
    reconciler = recorder(
      MinecraftServerLogMonitor => result(:reset, 2),
      IrcBot => result(:cleared, 1)
    )

    assert_equal({
      MinecraftServerLogMonitor::QUEUE => :reset,
      IrcBot::QUEUE => :cleared
    }, call_policy(reconciler, irc_enabled: false))
    assert_equal false, reconciler.calls.last.fetch(:enabled)
    assert_includes @log_output.string, 'queue=irc_bot result=cleared pending=1'
  end

  def test_backend_errors_propagate
    backend_error = RuntimeError.new('backend unavailable')
    reconciler = QueueReconcilerRecorder.new(error: backend_error)

    raised = assert_raises(RuntimeError) { call_policy(reconciler) }

    assert_same backend_error, raised
  end

private
  def call_policy(reconciler, irc_enabled: true)
    MinecraftWorkerQueuePolicy.call(
      resque: @resque,
      logger: @logger,
      irc_enabled: irc_enabled,
      server_log: @server_log,
      queue_reconciler: reconciler
    )
  end

  def recorder(results)
    QueueReconcilerRecorder.new(results: results)
  end

  def result(status, pending)
    ResqueQueueReconciler::Result.new(status: status, pending: pending)
  end
end
