require 'summer'

class IrcBot < Summer::Connection
  @queue = :irc_bot
  @shall_monitor = false
  
  TROTTLE = 1
  OP_COMMANDS = %w(opself opme quit_irc kick latest chatlog rcon)
  COMMANDS = %w(help info bancheck playercheck list say)

  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
  
  def self.perform(options = {})
    unless Preference.irc_server_host && Preference.irc_server_port.to_i
      Rails.logger.info "IRC Bot not started."
    end
    
    if options['start_irc_bot']
      Rails.logger.info "Starting IRC Bot"
      IrcBot.new(Preference.irc_server_host, Preference.irc_server_port.to_i)
      Rails.logger.info "Stopped IRC Bot"
    else
      Rails.logger.warn "Ignoring: #{options}"
    end
  end

  def op_nicks
    ops = Preference.irc_channel_ops
    
    ops.split(/[\s,]+/) if !!ops
  end

  # Summer callbacks

  def did_start_up
    Rails.logger.info "Started IRC Bot"
    
    monitor_replies
  end
  
  def channel_message sender, channel, message
    Rails.logger.info "#{sender.inspect} :: #{channel.inspect} :: #{message}"
    at, command = message.split(' ')

    return unless at == '@cobblebot' || at == '@cb' || at == '@server'
    command = command.downcase

    if op_nicks.include?(sender[:nick]) && OP_COMMANDS.include?(command)
      Thread.start do
        send(command, sender: sender, channel: channel, message: message)
      end
    end

    if COMMANDS.include?(command)
      Thread.start do
        send(command, sender: sender, channel: channel, message: message)
      end
    end
  end
  
  def private_message sender, bot, message
    Rails.logger.info "#{sender.inspect} :: (privately) :: #{message}"
    words = message.split(' ')
    command = words[0].downcase

    if op_nicks.include?(sender[:nick]) && OP_COMMANDS.include?(command)
      Thread.start do
        send(command, sender: sender, message: "@cobblebot #{message}")
      end
    end

    if COMMANDS.include?(command)
      Thread.start do
        send(command, sender: sender, message: "@cobblebot #{message}")
      end
    end
  end
  
  # Monitors
  
  def monitor_replies
    @shall_monitor = true
    @replies = Thread.start do
      begin
        sleep 15 and next unless ServerQuery.numplayers.to_i > 0
        
        IrcReply.all.find_each do |reply|
          channel_say(channel: config[:channel], reply: reply.body)
        
          reply.destroy
        end
      
        sleep 5
      end while @shall_monitor
    end
  end
  
  # IRC methods
  
  def reply(options = {})
    sender = options[:sender]
    channel = options[:channel]
    reply = options[:reply]

    if channel
      channel_say reply: reply
    else
      nick_msg sender: sender, reply: reply
    end
  end
  
  def channel_say(options = {})
    return if @connection.nil?

    channel = options[:channel]
    reply = options[:reply]

    response "PRIVMSG #{config[:channel]} :#{reply}"
    Rails.logger.info ">> #{reply}"
  end
  
  def nick_msg(options = {})
    sender = options[:sender]
    reply = options[:reply]
    msg = "#{sender[:nick]} :#{reply}"
    response "PRIVMSG #{msg}"
    Rails.logger.info ">> #{msg}"
  end
  
  # OP Commands
  
  def opself(options = {})
    response "PRIVMSG ChanServ OP #{config[:channel]} #{config[:nick]} +a"
  end
  
  def opme(options = {})
    response "MODE #{config[:channel]} +o #{sender[:nick]}"
  end

  def quit_irc(options = {})
    @shall_monitor = false
    response 'QUIT :Connection reset by beer.'
  end

  def kick(options = {})
    message = options[:message]
    
    words = message.split(' ')
    player =  words[2]
    reason = words[3..-1].join(' ')

    ServerCommand.kick player, reason
  end

  def latest(options = {})
    # TODO return the last 25 lines from latest.log
    # nick_msg(sender: sender, reply: "None.") and return unless === Logs present and has lines ===
    #
    #nick_msg sender: sender, reply: "Messages: #{=== current size of latest.log buffer ===}"
    # === latest.log buffer===.each do |line|
    #  nick_msg sender: sender, reply: line
    #  sleep TROTTLE
    #end
  end

  def chatlog(options = {})
    # Similar to def latest, but filter only player chat/emotes.
  end
  
  def rcon(options = {})
    message = options[:message]
    sender = options[:sender]
    
    words = message.split(' ')
    cmd = words[2..-1].join(' ')

    nick_msg sender: sender, reply: rcon(cmd)
  end

  # Regular commands.

  def help(options = {})
    message = options[:message]
    sender = options[:sender]
    
    words = message.split(' ')
    topic = words[2]

    case topic
    when 'info'
      nick_msg sender: sender, reply: "Usage: @cobblebot info"
    when 'bancheck'
      nick_msg sender: sender, reply: "Usage: @cobblebot bancheck <player>"
    when 'playercheck'
      nick_msg sender: sender, reply: "Usage: @cobblebot playercheck <player>"
    when 'list'
      nick_msg sender: sender, reply: "Usage: @cobblebot list"
    when 'say'
      nick_msg sender: sender, reply: "Usage: @cobblebot say <text>"
    else
      nick_msg sender: sender, reply: "Usage: @cobblebot help [topic]"
      nick_msg sender: sender, reply: "help | info | bancheck | playercheck | list | say"
    end
  end

  def info(options = {})
    sender = options[:sender]
    
    nick_msg sender: sender, reply: Preference.irc_info
  end

  def bancheck(options = {})
    message = options[:message]
    sender = options[:sender]
    channel = options[:channel]

    target = message.split(' ').last
    lines=[] # TODO get ban info for target
    lines.each do |line|
      reply sender: sender, channel: channel, reply: line
      sleep TROTTLE
    end
  end

  def playercheck(options = {})
    message = options[:message]
    sender = options[:sender]
    channel = options[:channel]

    nick = message.split(' ').last
    players = Player.any_nick(nick).order(:nick)
    
    if players.any?
      player = players.first
      reply sender: sender, channel: channel, reply: "Latest activity for #{player.nick} was #{distance_of_time_in_words_to_now(player.last_activity_at)} ago."
      sleep TROTTLE
      reply sender: sender, channel: channel, reply: "<#{player.nick}> #{player.last_chat} #{player.registered? ? '®' : ''}"
      sleep TROTTLE
      reply sender: sender, channel: channel, reply: "Biomes explored: #{player.explore_all_biome_progress}"
      # TODO get rate:
      # say "Sum of all trust: ..."
    else
      reply sender: sender, channel: channel, reply: "Player not found: #{nick}"
      sleep TROTTLE
      players = Player.search_any_nick(nick)
      reply sender: sender, channel: channel, reply: "Did you mean: #{players.first.nick}" if players.any?
    end
  end

  def list(options = {})
    sender = options[:sender]
    channel = options[:channel]

    msg = ServerCommand.execute('list').strip
    msg = msg.gsub(/:/, ': ')

    reply sender: sender, channel: channel, reply: msg
  end
  
  def say(options = {})
    message = options[:message]
    sender = options[:sender]

    words = message.split(' ')
    msg = words[2..-1].join(' ').gsub(/['`"]/, "\'")

    ServerCommand.irc_say sender[:nick], msg
  end
end

# Summer config

module Summer
  class Connection
    def load_config
      @config = {}
      @config[:nick] = Preference.irc_nick if !!Preference.irc_nick
      @config[:channels] = []
      @config[:channels] << @config[:channel] = Preference.irc_channel if !!Preference.irc_channel
      @config[:nickserv_password] = Preference.irc_nickserv_password if !!Preference.irc_nickserv_password
    end
  end
end