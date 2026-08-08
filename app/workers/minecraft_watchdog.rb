class MinecraftWatchdog
  QUEUE = :minecraft_watchdog
  @queue = QUEUE

  DEFERRED_OPERATIONS = %(update_player_quotes update_player_last_ip update_player_last_location)
  DEFERRED_MAX_RETRY = 5

  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end

  def self.perform(options = {})
    Rails.logger.info "Started #{self}"

    deferred_operation(options) if !!options['operation']

    # TODO do quick stuff on live Query::simpleQuery results
    # TODO look for any new crash logs, e.g.: hs_err_pid29380.log or crash-reports/crash-2015-03-14_13.01.01-server.txt
    # TODO every so often (not every watchdog invocation) crack open the latest.log to see what's going on

    MinecraftWorkerQueuePolicy.call
    check_resource_pack
    prettify_callbacks
    update_ip_cc
    update_player_stats
  rescue Errno::ENOENT => e
    Rails.logger.error "Need to finish setup: #{e.inspect}"
    nil
  rescue Resque::TermException
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
      %i[pattern command].each do |key|
        next if callback.public_send("pretty_#{key}").present?

        begin
          callback.prettify(key)
        rescue StandardError => e
          Rails.logger.warn CobbleBotError.new(
            message: "Unable to prettify ServerCallback #{callback.id} #{key}.",
            cause: e
          ).local_backtrace
        end
      end
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

end
