class MinecraftWatchdog
  @queue = :minecraft_watchdog

  WATCHDOG_TICK = 300
  DEFERRED_OPERATIONS = %(update_player_quotes update_player_last_ip update_player_last_location)
  DEFERRED_MAX_RETRY = 5
  
  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
  
  def self.perform(options = {})
    Rails.logger.info "Started #{self}"

    deferred_operation(options) if !!options['operation']
    
    begin
      # TODO do quick stuff on live Query::simpleQuery results
      # TODO look for any new crash logs, e.g.: hs_err_pid29380.log or crash-reports/crash-2015-03-14_13.01.01-server.txt
      # TODO every so often (not every watchdog tick) crack open the latest.log to see what's going on

      check_resque
      check_resource_pack
      prettify_callbacks
      update_ip_cc
      update_player_stats
      start_slack_bot_rtm

      break if !!options[:debug]      
      if Resque.size(@queue) < 6
        Rails.logger.info "#{self} sleeping for #{WATCHDOG_TICK}"
        sleep WATCHDOG_TICK
      end
    rescue Errno::ENOENT => e
      Rails.logger.error "Need to finish setup: #{e.inspect}"
      sleep WATCHDOG_TICK * 4
    end while Resque.size(@queue) < 4
  rescue Resque::TermException => e
    Rails.logger.info "Detected ^C"
  end
private
  def self.deferred_operation(options)
    op = options['operation']
    
    if DEFERRED_OPERATIONS.include? op
      begin
        ActiveRecord::Base.transaction do
          MinecraftWatchdog.send(op, options)
        end
      rescue => e
        options[:last_exception] = CobbleBotError.new(message: "Unable to execute deferred operation.", cause: e).local_backtrace
        _retry(options)
      end
    else
      Rails.logger.error "Unknown operation: #{op}"
    end
  end

  def self._retry(options = {})
    retry_count = options['retry_count'].to_i + 1
    
    if retry_count < DEFERRED_MAX_RETRY
      sleep 5 + retry_count
      options['retry_count'] = retry_count
      Resque.enqueue(MinecraftWatchdog, options) unless Rails.env == 'test'
    else
      Rails.logger.warn "Gave up: #{options.inspect}"
    end
  end

  def self.check_resque
    # Make sure the other workers are queued and working (like IRC and Log Monitor)
    
    queues = {
      minecraft_server_log_monitor: {
        class: MinecraftServerLogMonitor,
        options: {server_log: "#{ServerProperties.path_to_server}/logs/latest.log", max_ticks: 1200},
        max_queues: 5,
        min_queues: 5,
        enabled: true
      },
      irc_bot: {
        class: IrcBot,
        options: {start_irc_bot: true},
        max_queues: 1,
        min_queues: 1,
        enabled: Preference.irc_enabled?
      },
      minecraft_watchdog: {
        class: MinecraftWatchdog,
        options: {},
        max_queues: 5,
        min_queues: 5,
        enabled: true
      }
    }

    return if Rails.env == 'test'

    queues.each_key do |key|
      q = queues[key]
      if q[:enabled] && Resque.size(key.to_s) == 0
        Rails.logger.info "Adding queue for #{key}.  Current queue: #{Resque.size(key.to_s)}"
        Resque.enqueue(q[:class], q[:options])
      end
    end
    
    Resque.queues.each do |queue|
      if !!(q = queues[queue.to_sym])
        unless q[:enabled]
          Resque.dequeue(queue) unless Resque.size(queue) == 0
          Rails.logger.info "Skipping disabled queue: #{queue}: #{Resque.size(queue)}"
          next
        end
        
        if Resque.size(queue) > q[:max_queues] && q[:class] != MinecraftWatchdog
          Rails.logger.info "Dequeuing #{queue}.  Current queue: #{Resque.size(queue)}"
          Resque.dequeue(q[:class])
        end

        if Resque.size(queue) < q[:min_queues]
          Rails.logger.info "Enqueuing #{queue}.  Current queue: #{Resque.size(queue)}"
          Resque.enqueue(q[:class], q[:options])
        end
      else
        Rails.logger.info "Skipping unknown queue: #{queue}: #{Resque.size(queue)}"
      end
    end

    # TODO Also check that the correct number of workers are actually working the above queues, warn if not.
  end
  
  # Every so often, download the resource-pack and cache the hash.
  def self.check_resource_pack
    if !!ServerProperties.resource_pack
      latest_resource_pack_timestamp = Preference.latest_resource_pack_timestamp.to_i
      timestamp = Time.at(latest_resource_pack_timestamp) if !!latest_resource_pack_timestamp
      
      if 24.hours.ago > timestamp
        begin
          agent = CobbleBotAgent.new
          agent.get ServerProperties.resource_pack.gsub(/\\/, '')

          resource_pack_hash = Digest::MD5.hexdigest(agent.page.body) if agent.page
        rescue StandardError => e
          Rails.logger.error e.inspect
        end
        
        Preference.latest_resource_pack_hash = resource_pack_hash
        Preference.latest_resource_pack_timestamp = Time.now.to_i
      end
    end
  end
  
  def self.prettify_callbacks
    ServerCallback.needs_prettification.find_each do |callback|
      callback.prettify(:pattern) unless !!callback.pretty_pattern
      callback.prettify(:command) unless !!callback.pretty_command
    end
  end
  
  def self.update_ip_cc
    Player.where.not(last_ip: nil).where.not(id: Ip.all.select(:player_id)).find_each do |player|
      player.ips.create(address: player.last_ip)
    end
    
    ips = Ip.where(cc: nil).pluck(:address).uniq
    
    ips.each do |ip|
      break unless !!Ip.send(:update_cc, ip)
    end
  end
  
  def self.update_player_stats(deadline = 0.25)
    start = Time.now.to_f
    
    [].tap do |a|
      begin
        ActiveRecord::Base.transaction do
          Player.shall_update_stats.find_each do |player|
            break if Time.now.to_f - start > deadline
            a << {player_id: player.id, stats_updated: player.update_stats!}
          end
        end
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.warn "#{e.inspect} (can retry later)"
      rescue => e
        Rails.logger.warn CobblebotError.new(e).local_backtrace
      end
    end
  end

  def self.update_player_quotes(options)
    message = options['message']
    at = Time.at(options['at'].to_i)
    player = Player.find_by_nick(options['nick'])
    _retry(options) and return if player.nil?
    
    player.quotes.create(body: message) unless player.last_pvp_loss_has_quote?(at)
    player.quotes.create(body: message) unless player.last_pvp_win_has_quote?(at)
  end
  
  def self.update_player_last_ip(options)
    player = Player.find_by_nick(options['nick'])
    _retry(options) and return if player.nil?
    
    address = options['address']
    return if player.last_ip == address

    player.update_attribute(:last_ip, address) # no AR callbacks
    player.ips.create(address: address)
  end
  
  def self.update_player_last_location(options)
    player = Player.find_by_nick(options['nick'])
    _retry(options) and return if player.nil?

    x = options['x']
    y = options['y']
    z = options['z']
    player.update_attribute(:last_location, "x=#{x.to_i},y=#{y.to_i},z=#{z.to_i}") # no AR callbacks
  end
  
  def self.start_slack_bot_rtm
    @slack_bot_thread = nil unless !!@slack_bot_thread && @slack_bot_thread.alive?
    
    @slack_bot_thread ||= Thread.start do
      @slack_bot = SlackBot.new
      client = @slack_bot.realtime

      client.on :hello do
        Rails.logger.info "SlackBot realtime client started."
      end
      
      client.on :message do |data|
        begin
          Rails.logger.info data.inspect
          
          channel = data['channel']
          return unless channel == Preference.slack_group
          
          message = data['text'].force_encoding('UTF-8')
          return if message.nil?
          
          at, command = message.split(' ')
          return unless at == '@cobblebot' || at == '@cb' || at == '@server'
        
          Rails.logger.info command
        
          case command
          when /^list$/
            msg = ServerCommand.execute('list') || ''
            msg = msg.strip
            msg = msg.gsub(/:/, ': ')

            @slack_bot.say msg
          when /^say$/
            words = message.split(' ')
            if words.size > 2
              msg = words[2..-1].join(' ').gsub(/['`"]/, "\'")
              user_info = @slack_bot.users_info user: data['user']
              if !!user_info
                ServerCommand.say "@a", msg, as: user_info['user']['name'], color: 'white'
              end
            end
          else
            @slack_bot.say "Sorry <@#{data['user']}>, what?"
          end
        rescue => e
          Rails.logger.error e.inspect
        end
      end
      
      client.start
    end
  end
end
