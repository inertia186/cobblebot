require 'logger'
require 'summer'

# General purpose IRC client.  But it also works for Twitch chat (with tweaks).  For specific tweaks, see: http://help.twitch.tv/customer/portal/articles/1302780-twitch-irc
class SummerBot < Summer::Connection
  THROTTLE = 1
  
  attr_accessor :bot_started_at, :shall_monitor, :op_commands, :commands, :debug, :throttle

  @shall_monitor = false
  @bot_started_at = nil
  @op_commands = nil
  @commands = nil
  @debug = nil
  @throttle = THROTTLE
  
  def initialize(options = {})
    options.each do |k, v|
      send("#{k}=", v)
    end
    
    unless !!@debug
      super Preference.irc_server_host, Preference.irc_server_port.to_i
    end
  end

  def log info
    @log ||= Logger.new(config[:log_file], 'daily')
    @log.info info.strip
  end

  def log_error error
    @log ||= Logger.new(config[:log_file], 'daily')
    @log.error error
  end

  def shall_monitor=(shall_monitor)
    @shall_monitor = shall_monitor
  end

  def shall_monitor
    @shall_monitor
  end

  def op_commands=(op_commands)
    @op_commands = op_commands
  end

  def op_commands
    @op_commands || []
  end
  
  def commands=(commands)
    @commands = commands
  end

  def commands
    @commands || []
  end
  
  def op_nicks
    ops = Preference.irc_channel_ops
    
    ops.split(/[\s,]+/) if !!ops
  end

  def irc_channel
    config[:channel]
  end

  def irc_nick
    config[:nick]
  end

  # Summer callbacks

  def load_config
    @config = {}
    @config[:nick] = Preference.irc_nick if !!Preference.irc_nick
    @config[:channels] = []
    @config[:channels] << @config[:channel] = Preference.irc_channel if !!Preference.irc_channel
    @config[:nickserv_password] = Preference.irc_nickserv_password if !!Preference.irc_nickserv_password
    @config[:log_file] = "#{Rails.root}/log/irc.log"
    
    File.open(@config[:log_file], 'a').close
  end

  def connect!
    begin
      Preference.active_in_irc = 0 # Reset to zero until JOIN messages come in.
      @connection = TCPSocket.open(server, port)
      @connection = OpenSSL::SSL::SSLSocket.new(@connection).connect if config[:use_ssl]
      if twitch?
        response("PASS #{config[:nickserv_password]}") if config[:nickserv_password]
        response("NICK #{config[:nick]}")
      else
        response("USER #{config[:nick]} #{config[:nick]} #{config[:nick]} #{config[:nick]}")
        response("PASS #{config[:server_password]}") if config[:server_password]
        response("NICK #{config[:nick]}")
      end
    rescue Errno::EIO => e
      log e.inspect
    rescue StandardError => e
      log e.inspect
    end
  end

  def startup!
    @started = true
    did_start_up

    if config['nickserv_password']
      privmsg("identify #{config['nickserv_password']}", "nickserv")
      # Wait 10 seconds for nickserv to get back to us.
      Thread.new do
        sleep(10)
        finalize_startup
      end
    else
      finalize_startup
    end
  end
    
  def finalize_startup
    if twitch?
      # Twitch requires all CAP REQ calls happen before JOIN.
      response("CAP REQ :twitch.tv/membership")
      response("CAP REQ :twitch.tv/commands")
    else
      config[:channels] ||= []
      (config[:channels] << config[:channel]).compact.each do |channel|
        join(channel)
      end
    end
  end
  
  def did_start_up
    self.bot_started_at = Time.now
    log "Started IRC Bot at #{@bot_started_at}"

    count = Message::IrcReply.destroy_all.size
    log "Removed stale irc replies: #{count}" if count > 0
    
    monitor_replies
  end
  
  def channel_message sender, channel, message
    response 'NAMES' unless Preference.active_in_irc.to_i > 0
    
    log "#{sender.inspect} :: #{channel.inspect} :: #{message}"
    at, command = message.split(' ')

    return unless at == '@cobblebot' || at == '@cb' || at == '@server'
    return unless !!command
    command = command.downcase

    Thread.start do
      send(command, sender: sender, channel: channel, message: message)
    end if valid_op_command?(sender[:nick], command) || valid_command?(command)
  end
  
  def private_message sender, bot, message
    response 'NAMES' unless Preference.active_in_irc.to_i > 0
    
    log "#{sender.inspect} :: (privately) :: #{message}"
    words = message.split(' ')
    command = words[0].downcase

    Thread.start do
      send(command, sender: sender, message: "@cobblebot #{message}")
    end if valid_op_command?(sender[:nick], command) || valid_command?(command)
  end

  def parse message
    log ">> #{message}"

    super
    
    words = message.split(" ")
    sender = words[0]
    raw = words[1]
    channel = words[2]
          
    # Note, for some reason, Summer will not send callbacks, so we will.
    
    if raw == 'CAP'
      if message =~ /ACK :twitch.tv\/membership/
        # Now that twitch has acknowledged this request, we can join the channel and request NAMES.
        response("JOIN #{irc_channel}")
        response "NAMES"
      elsif message =~ /NAK :twitch.tv\/membership/
        response("JOIN #{irc_channel}")
      end
    elsif raw == 'NOTICE'
      response 'QUIT' if message =~ /Error logging in/
    elsif raw == "JOIN"
      join_event parse_sender(sender), channel
    elsif raw == "PART"
      part_event parse_sender(sender), channel, words[3..-1].clean
    elsif raw == "QUIT"
      quit_event parse_sender(sender), words[2..-1].clean
    elsif raw == "KICK"
      kick_event parse_sender(sender), channel, words[3], words[4..-1].clean
    elsif raw == '353'
      handle_353 message
    elsif raw == '366'
      handle_366 message
    elsif raw == '421'
      handle_421 message
    end
  end
  
  def handle_353 message
    @names_list ||= []
    names = message.split("#{irc_channel} :")[1]
    @names_list += names.split(' ')
    
    @names_list -= [config[:nick]]
  end
  
  def handle_366 message
    Preference.active_in_irc = @names_list.size
    @names_list = []
  end

  def handle_421 message
    if message =~ /NAMES :Unknown command/
      # Sometimes Twitch will disable the NAMES command for events like e3.  See: https://discuss.dev.twitch.tv/t/join-part-changes-temporary-and-future/2519
      Preference.active_in_irc = 1
    end
  end
  
  def join_event sender, channel
    return if sender[:nick] == config[:nick]
    
    active = Preference.active_in_irc.to_i
    Preference.active_in_irc = active + 1
    
    IrcBot.irc_say_event('@a', "#{sender[:nick]} joined the channel")
  end
  
  def part_event sender, channel, message
    return if sender[:nick] == config[:nick]
    
    active = Preference.active_in_irc.to_i
    Preference.active_in_irc = active - 1 unless active == 0

    IrcBot.irc_say_event('@a', "#{sender[:nick]} left the channel")
  end
  
  def quit_event sender, message
    return if sender[:nick] == config[:nick]
    
    active = Preference.active_in_irc.to_i
    Preference.active_in_irc = active - 1 unless active == 0

    IrcBot.irc_say_event('@a', "#{sender[:nick]} quit: #{message}")
  end

  def kick_event kicker, channel, victim, message
    return if sender[:nick] == config[:nick]
    
    active = Preference.active_in_irc.to_i
    Preference.active_in_irc = active - 1 unless active == 0

    IrcBot.irc_say_event('@a', "#{sender[:nick]} was kicked from IRC")
  end
  
  # Monitors
  
  def monitor_replies
    @shall_monitor = true
    @replies = Thread.start do
      begin
        quit_irc if should_quit_irc?
        sleep 15 and next if should_monitor_sleep?
        
        channel_say_irc_replies(channel: irc_channel)
        sleep 5
      rescue StandardError => e
        log_error e.inspect
        sleep 30
      end while @shall_monitor
    end
  end
  
  # IRC methods
  
  # This method will reply to the channel or as a private message dpending on
  # what options are set.  If channel is set, the response goes to the whole
  # channel.  But if channel is nil, the response is sent privately (or not at
  # all).
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

    response "PRIVMSG #{irc_channel} :#{reply}"
    sleep @throttle || THROTTLE
    log ">> #{reply}"
  end
  
  def nick_msg(options = {})
    if twitch?
      channel_say(options)
    else
      sender = options[:sender]
      reply = options[:reply]
      msg = "#{sender[:nick]} :#{reply}"
      response "PRIVMSG #{msg}"
      sleep @throttle || THROTTLE
      log ">> #{msg}"
    end
  end
private
  def valid_op_command?(nick, command)
    op_nicks.include?(nick) && op_commands.include?(command)
  end
  
  def valid_command?(command)
    commands.include? command
  end

  def channel_say_irc_replies(options = {})
    Message::IrcReply.all.find_each do |reply|
      response 'NAMES'
      
      options[:reply] = reply.body
      channel_say(options)
    
      reply.destroy
    end
  end

  def should_monitor_sleep?
    !Server.up? || (
      ServerQuery.numplayers.to_i < 1 &&
      ServerQuery.active_in_irc.to_i < 1 &&
      Message::IrcReply.all.none? 
    )
  end
  
  def should_quit_irc?
    !Preference.irc_enabled? || @bot_started_at.nil? || @bot_started_at < 24.hours.ago
  end
  
  def twitch?
    !!config[:nickserv_password] && config[:nickserv_password] =~ /^oauth/
  end
end
