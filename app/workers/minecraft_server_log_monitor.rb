class MinecraftServerLogMonitor
  QUEUE = :minecraft_server_log_monitor
  @queue = QUEUE

  DEFAULT_LOG_LENGTH = 1000
  DEFAULT_MONITOR_TICK = 0.25
  DEFAULT_TICK_MULTIPLIER = 2
  DEFAULT_MAX_TICKS = 12000

  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
    
  def self.perform(options = {})
    Rails.logger.info "Started #{self}"

    # Rake tasks do not honor production eager loading. Load every callback STI
    # type before ServerEntry builds its descendant-aware query.
    ServerCallback.preload_sti_types!

    server_log = options["server_log"] || "#{ServerProperties.path_to_server}/logs/latest.log"
    log_length = options["log_length"] || DEFAULT_LOG_LENGTH
    monitor_tick = options["monitor_tick"] || DEFAULT_MONITOR_TICK
    tick_multiplier = options["tick_multiplier"] || DEFAULT_TICK_MULTIPLIER
    max_ticks = options["max_ticks"] || DEFAULT_MAX_TICKS

    MinecraftServerLogTailer.call(
      server_log: server_log,
      log_length: log_length,
      monitor_tick: monitor_tick,
      tick_multiplier: tick_multiplier,
      max_ticks: max_ticks
    )
  end
end
