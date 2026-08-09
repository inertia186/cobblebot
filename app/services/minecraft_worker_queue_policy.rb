class MinecraftWorkerQueuePolicy
  MONITOR_MAX_TICKS = 1200

  def self.call(resque: Resque, logger: Rails.logger,
                irc_enabled: Preference.irc_enabled?,
                server_log: "#{ServerProperties.path_to_server}/logs/latest.log",
                queue_reconciler: ResqueQueueReconciler)
    new(
      resque: resque,
      logger: logger,
      irc_enabled: irc_enabled,
      server_log: server_log,
      queue_reconciler: queue_reconciler
    ).call
  end

  def initialize(resque:, logger:, irc_enabled:, server_log:, queue_reconciler:)
    @resque = resque
    @logger = logger
    @irc_enabled = irc_enabled
    @server_log = server_log
    @queue_reconciler = queue_reconciler
  end

  def call
    {
      MinecraftServerLogMonitor::QUEUE => reconcile(
        MinecraftServerLogMonitor,
        enabled: true,
        options: {server_log: @server_log, max_ticks: MONITOR_MAX_TICKS}
      ),
      IrcBot::QUEUE => reconcile(
        IrcBot,
        enabled: @irc_enabled,
        options: {start_irc_bot: true}
      )
    }
  end

private
  def reconcile(worker_class, enabled:, options:)
    queue = worker_class::QUEUE
    result = @queue_reconciler.call(
      resque: @resque,
      worker_class: worker_class,
      enabled: enabled,
      args: [options]
    )

    log(queue, result.status, result.pending)
    result.status
  end

  def log(queue, result, pending)
    @logger.info "Worker queue policy: queue=#{queue} result=#{result} pending=#{pending}"
  end
end
