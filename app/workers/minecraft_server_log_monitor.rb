class MinecraftServerLogMonitor
  @queue = :minecraft_server_log_monitor

  LOG_LENGTH = 100
  MONITOR_TICK = 0.25

  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
    
  def self.perform
    Rails.logger.info "Started #{self}"

    server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
    server_log_ctime = nil
    server_msgs = []

    begin
      new_server_log_ctime = File.ctime(server_log)

      if server_log_ctime != new_server_log_ctime
        server_log_ctime = new_server_log_ctime
        
        File.open(server_log) do |log|
          unique_lines = []
          log.extend(File::Tail)
          log.max_interval = MONITOR_TICK * 2
          log.interval = MONITOR_TICK
          log.backward(0)
          log.tail LOG_LENGTH do |line|
            unless unique_lines.include?(line)
              MinecraftServerLogHandler.handle line
              unique_lines << line
            end
          end
        end
      end
      
      sleep MONITOR_TICK
    rescue Errno::ENOENT => e
      Rails.logger.error "Need to finish setup: #{e.inspect}"
      sleep 300
    end while Resque.size(@queue) < 4
  end
end