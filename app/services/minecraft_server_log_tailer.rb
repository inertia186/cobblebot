class MinecraftServerLogTailer
  def self.call(server_log:, log_length:, monitor_tick:, tick_multiplier:,
                max_ticks:, file_opener: File,
                handler: MinecraftServerLogHandler, logger: Rails.logger,
                sleeper: Kernel,
                clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
    new(
      server_log: server_log,
      log_length: log_length,
      monitor_tick: monitor_tick,
      tick_multiplier: tick_multiplier,
      max_ticks: max_ticks,
      file_opener: file_opener,
      handler: handler,
      logger: logger,
      sleeper: sleeper,
      clock: clock
    ).call
  end

  def initialize(server_log:, log_length:, monitor_tick:, tick_multiplier:,
                 max_ticks:, file_opener:, handler:, logger:, sleeper:, clock:)
    @server_log = server_log
    @log_length = log_length
    @monitor_tick = monitor_tick
    @tick_multiplier = tick_multiplier
    @max_ticks = max_ticks
    @file_opener = file_opener
    @handler = handler
    @logger = logger
    @sleeper = sleeper
    @clock = clock
  end

  def call
    log = open_log
    return :missing unless log

    configure(log)
    tail(log)

    :completed
  rescue Resque::TermException
    @logger.info 'Detected ^C'
    :terminated
  ensure
    log.close if log&.respond_to?(:close)
  end

private
  def open_log
    @file_opener.open(@server_log)
  rescue Errno::ENOENT => error
    @logger.error "Need to finish setup: #{error.inspect}"
    nil
  end

  def configure(log)
    log.extend(File::Tail)
    log.max_interval = @monitor_tick * @tick_multiplier
    log.interval = @monitor_tick
    log.return_if_eof = true
    log.backward(0)
  end

  def tail(log)
    @max_ticks.times do
      log.tail(@log_length) do |line|
        started_at = @clock.call
        @handler.handle(line)

        elapsed = @clock.call - started_at
        if elapsed > @monitor_tick
          @logger.warn "Logging interval elapsed time greater than monitor tick: #{elapsed} seconds"
        end
      end

      @sleeper.sleep(@monitor_tick)
    end
  end
end
