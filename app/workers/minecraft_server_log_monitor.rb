class MinecraftServerLogMonitor
  @queue = :minecraft_server_log_monitor

  DEFAULT_LOG_LENGTH = 100
  DEFAULT_MONITOR_TICK = 0.25
  DEFAULT_TICK_MULTIPLIER = 2
  DEFAULT_MAX_TICKS = 1200

  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
    
  def self.perform(options = {})
    Rails.logger.info "Started #{self}"

    server_log = options["server_log"] || "#{ServerProperties.path_to_server}/logs/latest.log"
    log_length = options["log_length"] || DEFAULT_LOG_LENGTH
    monitor_tick = options["monitor_tick"] || DEFAULT_MONITOR_TICK
    tick_multiplier = options["tick_multiplier"] || DEFAULT_TICK_MULTIPLIER
    max_ticks = options["max_ticks"] || DEFAULT_MAX_TICKS

    ticks = 0
    latest_log_entry_at = nil
    server_msgs = []

    begin
      new_latest_log_entry_at = Server.latest_log_entry_at

      if latest_log_entry_at != new_latest_log_entry_at
        latest_log_entry_at = new_latest_log_entry_at
        File.open(server_log) do |log|
          unique_lines = []
          log.extend(File::Tail)
          log.max_interval = monitor_tick * tick_multiplier
          log.interval = monitor_tick
          log.backward(0)
          log.tail log_length do |line|
            start = Time.now
            unless unique_lines.include?(line)
              unique_lines << line
              h = Thread.start do
                MinecraftServerLogHandler.handle line
              end
              h.join(monitor_tick) # throttle
            end
            elapsed = Time.now - start
            puts "Logging interval elapsed time: #{elapsed} seconds"
          end
        end
      end

      ticks = ticks + 1      
      sleep monitor_tick
    rescue Errno::ENOENT => e
      Rails.logger.error "Need to finish setup: #{e.inspect}"
      sleep 300
    end while max_ticks > ticks && Resque.size(@queue) < 4
  end
end