class MinecraftWatchdog
  @queue = :minecraft_watchdog

  WATCHDOG_TICK = 60
  
  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
  
  def self.perform
    Rails.logger.info "Started #{self}"

    begin
      # TODO do quick stuff on live Query::simpleQuery results
      # TODO look for any new crash logs, e.g.: hs_err_pid29380.log or crash-reports/crash-2015-03-14_13.01.01-server.txt
      # TODO every so often (not every watchdog tick) crack open the latest.log to see what's going on

      # Make sure the other workers are queued and working (like IRC and Log Monitor)
      Resque.queues.each do |queue|
        case queue
        when 'minecraft_server_log_monitor'
          if Resque.size(queue) > 5
            Rails.logger.info "Dequeuing #{queue}.  Current queue: #{Resque.size(queue)}"
            Resque.dequeue(MinecraftServerLogMonitor)
          end
          
          if Resque.size(queue) < 5
            Rails.logger.info "Enqueuing #{queue}.  Current queue: #{Resque.size(queue)}"
            Resque.enqueue(MinecraftServerLogMonitor)
          end
        when 'irc_bot'
          if Resque.size(queue) > 1
            Rails.logger.info "Dequeuing #{queue}.  Current queue: #{Resque.size(queue)}"
            Resque.dequeue(IrcBot)
          end
          
          if Resque.size(queue) < 1 && Preference.irc_enabled?
            Rails.logger.info "Enqueuing #{queue}.  Current queue: #{Resque.size(queue)}"
            Resque.enqueue(IrcBot, start_irc_bot: true)
          end
        when 'minecraft_watchdog'
          if Resque.size(queue) > 5
            Rails.logger.info "Dequeuing #{queue}.  Current queue: #{Resque.size(queue)}"
            Resque.dequeue(MinecraftWatchdog)
          end
        else
          puts "Unknown queue: #{queue}: #{Resque.size(queue)}"
        end
      end

      # TODO Also check that the correct number of workers are actually working the above queues, warn if not.
      
      # Every so often, download the resource-pack and cache the hash.
      if !!ServerProperties.resource_pack
        latest_resource_pack_timestamp = Preference.latest_resource_pack_timestamp.to_i
        timestamp = Time.at(latest_resource_pack_timestamp) if !!latest_resource_pack_timestamp
        
        if 24.hours.ago > timestamp
          begin
            agent = Mechanize.new
            agent.keep_alive = false
            agent.open_timeout = 5
            agent.read_timeout = 5
            agent.get ServerProperties.resource_pack.gsub(/\\/, '')

            resource_pack_hash = Digest::MD5.hexdigest(agent.page.body) if agent.page
          rescue StandardError => e
            Rails.logger.error e.inspect
          end
          
          Preference.latest_resource_pack_hash = resource_pack_hash
          Preference.latest_resource_pack_timestamp = Time.now.to_i
        end
      end
      
      Rails.logger.info "#{self} sleeping for #{WATCHDOG_TICK}"
      sleep WATCHDOG_TICK
    rescue Errno::ENOENT => e
      Rails.logger.error "Need to finish setup: #{e.inspect}"
      sleep 300
    end while Resque.size(@queue) < 4
  end
end