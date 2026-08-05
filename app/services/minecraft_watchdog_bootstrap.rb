class MinecraftWatchdogBootstrap
  REDIS_UNAVAILABLE_MESSAGE = 'Unable to bootstrap Minecraft watchdog: Redis is unavailable.'

  def self.call(resque: Resque, logger: Rails.logger)
    new(resque: resque, logger: logger).call
  end

  def initialize(resque:, logger:)
    @resque = resque
    @logger = logger
  end

  def call
    if watchdog_present?
      logger.info 'Minecraft watchdog is already queued or running.'
      :already_present
    else
      resque.enqueue(MinecraftWatchdog)
      logger.info 'Enqueued Minecraft watchdog.'
      :enqueued
    end
  rescue Redis::BaseConnectionError, SystemCallError, SocketError => error
    raise CobbleBotError.new(message: REDIS_UNAVAILABLE_MESSAGE, cause: error)
  end

private
  attr_reader :logger, :resque

  def watchdog_present?
    resque.size(MinecraftWatchdog::QUEUE.to_s).positive? || watchdog_running?
  end

  def watchdog_running?
    resque.working.any? do |worker|
      job = worker.job || {}
      payload = job['payload'] || job[:payload] || {}
      worker_class = payload['class'] || payload[:class]

      worker_class.to_s == MinecraftWatchdog.name
    end
  end
end
