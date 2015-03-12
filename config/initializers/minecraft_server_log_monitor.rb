class MinecraftServerLogMonitor
  BUFFER = 24
  
  cattr_accessor :server_log_monitor
  attr_accessor :server_log, :server_msgs

  def server_msgs
    @server_msgs ||= []
  end

  def start_server_log_monitor!
    stop_server_log_monitor
    start_server_log_monitor
  end
  
  def start_server_log_monitor
    return unless path_to_server = Preference.path_to_server
    return if @shall_monitor_server_log
    return if @@server_log_monitor && @@server_log_monitor.alive?

    Rails.logger.info "Starting minecraft server log monitor."
    
    @shall_monitor_server_log = true
    @server_log = File.open("#{path_to_server}/logs/latest.log")

    @@server_log_monitor = Thread.start do
      begin
        while(@shall_monitor_server_log) do
          lines = IO.readlines(@server_log)[-(BUFFER / 2)..-1]
          sleep(10) and next if lines.nil?
        
          lines.each do |line|
            if server_msgs.length > (BUFFER / 2) && !server_msgs.include?(line)
              MinecraftServerLogHandler.handle line
            end
          
            server_msgs.push(line).slice!(0..-(BUFFER))
          end
          
          sleep 0.25
        end
      rescue StandardError => e
        Rails.logger.error e.inspect
      end
    end
  end
  
  def stop_server_log_monitor
    if @shall_monitor_server_log
      Rails.logger.info "Stopping minecraft server log monitor."
      @shall_monitor_server_log = false
    end
    
    return unless !!@@server_log_monitor
    
    if @@server_log_monitor.join(300)
      Rails.logger.info 'Minecraft server log monitor stopped cleanly.'
    else
      @@server_log_monitor.kill
      Rails.logger.error 'Minecraft server log monitor could not stop cleanly.'
    end
    
    @@server_log_monitor = nil
    
    true
  end
end

begin
  Rails.application.minecraft_server_log_monitor = MinecraftServerLogMonitor.new
  Rails.application.minecraft_server_log_monitor.start_server_log_monitor!
rescue ActiveRecord::StatementInvalid => e
  # This can happen on initial execution.
  Rails.logger.warn e.inspect
end