require 'logger'
require 'summer'

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
    @log.info info
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
    @connection = TCPSocket.open(server, port)
    @connection = OpenSSL::SSL::SSLSocket.new(@connection).connect if config[:use_ssl]
    if !!config[:nickserv_password] && config[:nickserv_password] =~ /^oauth/
      response("PASS #{config[:nickserv_password]}") if config[:nickserv_password]
      response("NICK #{config[:nick]}")
    else
      response("USER #{config[:nick]} #{config[:nick]} #{config[:nick]} #{config[:nick]}")
      response("PASS #{config[:server_password]}") if config[:server_password]
      response("NICK #{config[:nick]}")
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
    log "#{sender.inspect} :: (privately) :: #{message}"
    words = message.split(' ')
    command = words[0].downcase

    Thread.start do
      send(command, sender: sender, message: "@cobblebot #{message}")
    end if valid_op_command?(sender[:nick], command) || valid_command?(command)
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
    sender = options[:sender]
    reply = options[:reply]
    msg = "#{sender[:nick]} :#{reply}"
    response "PRIVMSG #{msg}"
    sleep @throttle || THROTTLE
    log ">> #{msg}"
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
      options[:reply] = reply.body
      channel_say(options)
    
      reply.destroy
    end
  end

  def should_monitor_sleep?
    !Server.up? || ( ServerQuery.numplayers.to_i < 1 && Message::IrcReply.all.none? )
  end
  
  def should_quit_irc?
    !Preference.irc_enabled? || @bot_started_at.nil? || @bot_started_at < 24.hours.ago
  end
end
