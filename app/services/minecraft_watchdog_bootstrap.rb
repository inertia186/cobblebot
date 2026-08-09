class MinecraftWatchdogBootstrap
  REDIS_UNAVAILABLE_MESSAGE = 'Unable to bootstrap Minecraft watchdog: Redis is unavailable.'

  def self.call(resque: Resque, logger: Rails.logger,
                queue_reconciler: ResqueQueueReconciler)
    new(
      resque: resque,
      logger: logger,
      queue_reconciler: queue_reconciler
    ).call
  end

  def initialize(resque:, logger:, queue_reconciler:)
    @resque = resque
    @logger = logger
    @queue_reconciler = queue_reconciler
  end

  def call
    result = queue_reconciler.call(
      resque: resque,
      worker_class: MinecraftWatchdog,
      args: [],
      consider_running: true
    )
    if result.status == :enqueued
      logger.info 'Enqueued Minecraft watchdog.'
    else
      logger.info 'Minecraft watchdog is already queued or running.'
    end
    result.status
  rescue Redis::BaseConnectionError, SocketError => error
    raise CobbleBotError.new(message: REDIS_UNAVAILABLE_MESSAGE, cause: error)
  end

private
  attr_reader :logger, :queue_reconciler, :resque
end
