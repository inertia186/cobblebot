require 'logger'
require 'summer'

class IrcBot < SummerBot
  attr_accessor :bot_started_at
  
  @queue = :irc_bot
  
  def self.before_perform_log_job(*args)
    Rails.logger.info "About to perform #{self} with #{args.inspect}"
  end
  
  def self.perform(options = {})
    unless Preference.irc_server_host && Preference.irc_server_port.to_i
      Rails.logger.info "IRC Bot not started."
    end
    
    if options['start_irc_bot'] && Preference.irc_enabled?
      Rails.logger.info "Starting IRC Bot"
      options = {}
      options[:op_commands] = %w(opself opme quit_irc kick latest chatlog rcon)
      options[:commands] = %w(help info bancheck playercheck list say)
      new(options)
      Rails.logger.info "Stopped IRC Bot"
    else
      Rails.logger.warn "Ignoring: #{options}"
    end
  end

  # OP Commands
  
  def opself(options = {})
    response "PRIVMSG ChanServ OP #{irc_channel} #{irc_nick} +a"
  end
  
  def opme(options = {})
    response "MODE #{irc_channel} +o #{sender[:nick]}"
  end

  def quit_irc(options = {})
    shall_monitor = false
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

    nick_msg sender: sender, reply: ServerCommand.execute(cmd)
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
    end
  end

  def playercheck(options = {})
    message = options[:message]
    sender = options[:sender]
    channel = options[:channel]

    nick = message.split(' ').last
    lines = ServerCommand.say_playercheck(nil, nick)
    
    if lines.class == Array
      lines.each do |line|
        reply sender: sender, channel: channel, reply: line
      end
    else
      Rails.logger.warn("Don't know what to do with: #{lines}")
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

    ServerCommand.irc_say "@a", sender[:nick], msg
  end
end
