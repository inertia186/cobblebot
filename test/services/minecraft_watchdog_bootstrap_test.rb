require 'test_helper'
require Rails.root.join('test/support/queue_reconciler_recorder')
require 'stringio'

class MinecraftWatchdogBootstrapTest < ActiveSupport::TestCase
  def setup
    @resque = Object.new
    @log_output = StringIO.new
    @logger = Logger.new(@log_output)
  end

  def test_delegates_singleton_ownership_to_the_reconciler
    reconciler = recorder(status: :enqueued, pending: 0)

    assert_equal :enqueued, call_bootstrap(reconciler)
    assert_equal [{
      resque: @resque,
      worker_class: MinecraftWatchdog,
      args: [],
      consider_running: true
    }], reconciler.calls
    assert_includes @log_output.string, 'Enqueued Minecraft watchdog.'
  end

  def test_reports_an_existing_queued_or_running_watchdog
    reconciler = recorder(status: :already_present, pending: 1)

    assert_equal :already_present, call_bootstrap(reconciler)
    assert_includes @log_output.string,
      'Minecraft watchdog is already queued or running.'
  end

  def test_wraps_redis_connection_errors
    redis_error = Redis::CannotConnectError.new('connection refused')
    reconciler = QueueReconcilerRecorder.new(error: redis_error)

    error = assert_raises(CobbleBotError) { call_bootstrap(reconciler) }

    assert_equal MinecraftWatchdogBootstrap::REDIS_UNAVAILABLE_MESSAGE, error.message
    assert_same redis_error, error.cause
  end

  def test_logger_system_errors_are_not_misreported_as_redis_failures
    reconciler = recorder(status: :enqueued, pending: 0)
    @logger.define_singleton_method(:info) { |_message| raise Errno::EIO, 'logger' }

    assert_raises(Errno::EIO) { call_bootstrap(reconciler) }
  end

private
  def call_bootstrap(reconciler)
    MinecraftWatchdogBootstrap.call(
      resque: @resque,
      logger: @logger,
      queue_reconciler: reconciler
    )
  end

  def recorder(status:, pending:)
    QueueReconcilerRecorder.new(
      results: {
        MinecraftWatchdog => ResqueQueueReconciler::Result.new(
          status: status,
          pending: pending
        )
      }
    )
  end
end
