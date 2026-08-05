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
    @file_opener.open(@server_log) do |log|
      configure(log)
      tail(log)
    end

    :completed
  rescue Errno::ENOENT => error
    @logger.error "Need to finish setup: #{error.inspect}"
    :missing
  rescue Resque::TermException
    @logger.info 'Detected ^C'
    :terminated
  end

private
  def configure(log)
    log.extend(File::Tail)
    log.max_interval = @monitor_tick * @tick_multiplier
    log.interval = @monitor_tick
    log.return_if_eof = true
    log.backward(0)
  end

  def tail(log)
    unique_lines = []
    lines_seen = 0

    @max_ticks.times do
      log.tail(@log_length) do |line|
        started_at = @clock.call
        unless unique_lines.include?(line)
          unique_lines << line
          @handler.handle(line)
        end

        lines_seen += 1
        if lines_seen >= @log_length
          unique_lines.clear
          lines_seen = 0
        end

        elapsed = @clock.call - started_at
        if elapsed > @monitor_tick
          @logger.warn "Logging interval elapsed time greater than monitor tick: #{elapsed} seconds"
        end
      end

      @sleeper.sleep(@monitor_tick)
    end
  end
end
