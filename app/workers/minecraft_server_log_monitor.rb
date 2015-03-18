class MinecraftServerLogMonitor
  @queue = :minecraft_server_log_monitor

  BUFFER = 24

  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
    
  def self.perform
    Rails.logger.info "Started #{self}"

    server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
    server_msgs = []

    begin
      lines = IO.readlines(server_log)[-(BUFFER / 2)..-1]
      sleep(10) and next if lines.nil?
    
      lines.each do |line|
        if server_msgs.length > (BUFFER / 2) && !server_msgs.include?(line)
          MinecraftServerLogHandler.handle line
        end
      
        server_msgs.push(line).slice!(0..-(BUFFER))
      end
      
      sleep 0.25
    rescue Errno::ENOENT => e
      Rails.logger.error "Need to finish setup: #{e.inspect}"
      sleep 300
    end while Resque.size(@queue) < 4
  end
end