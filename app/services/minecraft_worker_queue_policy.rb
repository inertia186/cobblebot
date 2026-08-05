class MinecraftWorkerQueuePolicy
  MONITOR_MAX_TICKS = 1200

  def self.call(resque: Resque, logger: Rails.logger,
                irc_enabled: Preference.irc_enabled?,
                server_log: "#{ServerProperties.path_to_server}/logs/latest.log")
    new(
      resque: resque,
      logger: logger,
      irc_enabled: irc_enabled,
      server_log: server_log
    ).call
  end

  def initialize(resque:, logger:, irc_enabled:, server_log:)
    @resque = resque
    @logger = logger
    @irc_enabled = irc_enabled
    @server_log = server_log
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
    pending = @resque.size(queue)

    unless enabled
      if pending.zero?
        log(queue, :disabled, pending)
        return :disabled
      end

      @resque.dequeue(worker_class)
      log(queue, :cleared, pending)
      return :cleared
    end

    case pending
    when 0
      @resque.enqueue(worker_class, options)
      result = :enqueued
    when 1
      result = :already_present
    else
      @resque.dequeue(worker_class)
      @resque.enqueue(worker_class, options)
      result = :reset
    end

    log(queue, result, pending)
    result
  end

  def log(queue, result, pending)
    @logger.info "Worker queue policy: queue=#{queue} result=#{result} pending=#{pending}"
  end
end
