require 'logger'
require 'set'
require 'summer'

# General purpose IRC client.  But it also works for Twitch chat (with tweaks).  For specific tweaks, see: http://help.twitch.tv/customer/portal/articles/1302780-twitch-irc
class SummerBot < Summer::Connection
  THROTTLE = 1
  IRC_ACCOUNT_CAPABILITY = 'account-tag'
  TWITCH_TAGS_CAPABILITY = 'twitch.tv/tags'
  TWITCH_CAPABILITIES = %w[
    twitch.tv/membership
    twitch.tv/commands
    twitch.tv/tags
  ].freeze
  
  attr_accessor :bot_started_at, :shall_monitor, :op_commands, :commands, :debug, :throttle
  attr_writer :command_dispatcher

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
      begin
        super Preference.irc_server_host, Preference.irc_server_port.to_i
      ensure
        shutdown_command_dispatcher
      end
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

  def response(message)
    (@response_mutex ||= Mutex.new).synchronize { super(message) }
  end

  def shall_monitor=(shall_monitor)
    @shall_monitor = shall_monitor
  end

  def shall_monitor
    @shall_monitor
  end

  def shutdown_command_dispatcher
    dispatcher = @command_dispatcher
    @command_dispatcher = nil
    dispatcher.shutdown if dispatcher&.respond_to?(:shutdown)
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
  
  def op_identities
    ops = Preference.irc_channel_ops

    ops ? ops.split(/[\s,]+/) : []
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
    @available_capabilities = Set.new
    @enabled_capabilities = Set.new
    @current_message_tags = {}
    @cap_negotiation_complete = false
    @response_mutex ||= Mutex.new
    @config[:nick] = Preference.irc_nick if !!Preference.irc_nick
    @config[:channels] = []
    @config[:channels] << @config[:channel] = Preference.irc_channel if !!Preference.irc_channel
    @config[:nickserv_password] = Preference.irc_nickserv_password if !!Preference.irc_nickserv_password
    @config[:log_file] = "#{Rails.root}/log/irc.log"
    
    File.open(@config[:log_file], 'a').close
  end

  def connect!
    tcp_connection = nil

    begin
      Preference.active_in_irc = 0 # Reset to zero until JOIN messages come in.
      tcp_connection = TCPSocket.open(server, port)
      @connection = config[:use_ssl] ? authenticated_tls_connection(tcp_connection) : tcp_connection
      response('CAP LS 302')

      if twitch?
        response("PASS #{config[:nickserv_password]}") if config[:nickserv_password]
        response("NICK #{config[:nick]}")
      else
        response("USER #{config[:nick]} #{config[:nick]} #{config[:nick]} #{config[:nick]}")
        response("PASS #{config[:server_password]}") if config[:server_password]
        response("NICK #{config[:nick]}")
      end
    rescue Errno::EIO => e
      close_failed_connection(tcp_connection)
      log e.inspect
    rescue StandardError => e
      close_failed_connection(tcp_connection)
      log e.inspect
    end
  end

  def startup!
    @started = true
    did_start_up

    if config[:nickserv_password]
      privmsg("identify #{config[:nickserv_password]}", "nickserv")
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
    config[:channels] ||= []
    config[:channels].compact.uniq.each do |channel|
      join(channel)
    end
  end

private
  def authenticated_tls_connection(tcp_connection)
    context = OpenSSL::SSL::SSLContext.new
    context.cert_store = OpenSSL::X509::Store.new.tap(&:set_default_paths)
    context.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)

    connection = OpenSSL::SSL::SSLSocket.new(tcp_connection, context)
    connection.hostname = server if connection.respond_to?(:hostname=)
    connection.connect
    connection.post_connection_check(server)
    connection
  end

  def close_failed_connection(tcp_connection)
    @connection.close if @connection && !@connection.closed?
    tcp_connection.close if tcp_connection && tcp_connection != @connection && !tcp_connection.closed?
    @connection = nil
  end

public
  
  def did_start_up
    self.bot_started_at = Time.now
    log "Started IRC Bot at #{@bot_started_at}"

    count = Message::IrcReply.destroy_all.size
    log "Removed stale irc replies: #{count}" if count > 0
    
    monitor_replies
  end
  
  def channel_message sender, channel, message
    sender = sender_with_authenticated_identity(sender)
    response 'NAMES' unless Preference.active_in_irc.to_i > 0
    
    log "#{sender.inspect} :: #{channel.inspect} :: #{message}"
    at, command = message.split(' ')

    return unless at == '@cobblebot' || at == '@cb' || at == '@server'
    return unless !!command
    command = command.downcase

    if valid_op_command?(sender, command) || valid_command?(command)
      dispatch_command(
        command,
        sender: sender,
        channel: channel,
        message: message
      )
    end
  end
  
  def private_message sender, bot, message
    sender = sender_with_authenticated_identity(sender)
    response 'NAMES' unless Preference.active_in_irc.to_i > 0
    
    log "#{sender.inspect} :: (privately) :: #{message}"
    words = message.split(' ')
    command = words[0].downcase

    if valid_op_command?(sender, command) || valid_command?(command)
      dispatch_command(
        command,
        sender: sender,
        message: "@cobblebot #{message}"
      )
    end
  end

  def parse message
    log ">> #{message}"
    tags, untagged_message = extract_message_tags(message)
    @current_message_tags = tags

    super untagged_message
    
    words = untagged_message.split(" ")
    sender = words[0]
    raw = words[1]
    channel = words[2]
          
    # Note, for some reason, Summer will not send callbacks, so we will.
    
    if raw == 'CAP'
      handle_capability_message(untagged_message)
    elsif raw == 'NOTICE'
      response 'QUIT' if untagged_message =~ /Error logging in/
    elsif raw == "JOIN"
      join_event parse_sender(sender), channel
    elsif raw == "PART"
      part_event parse_sender(sender), channel, words[3..-1].clean
    elsif raw == "QUIT"
      quit_event parse_sender(sender), words[2..-1].clean
    elsif raw == "KICK"
      kick_event parse_sender(sender), channel, words[3], words[4..-1].clean
    elsif raw == '353'
      handle_353 untagged_message
    elsif raw == '366'
      handle_366 untagged_message
    elsif raw == '421'
      handle_421 untagged_message
    end
  ensure
    @current_message_tags = {}
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
      # Preference.active_in_irc = 1
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
    return if victim == config[:nick]
    
    active = Preference.active_in_irc.to_i
    Preference.active_in_irc = active - 1 unless active == 0

    IrcBot.irc_say_event('@a', "#{victim} was kicked from IRC")
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
  def command_dispatcher
    @command_dispatcher ||= IrcCommandDispatcher.new
  end

  def dispatch_command(command, **options)
    sender = options.fetch(:sender)
    status = command_dispatcher.submit(command_rate_key(sender)) do
      send(command, **options)
    end

    log "Rejected IRC command: #{status}" unless status == :accepted
    status
  end

  def command_rate_key(sender)
    sender[:authenticated_identity].presence ||
      [sender[:nick], sender[:hostname]].compact.join('!').presence ||
      'unknown'
  end

  def valid_op_command?(sender, command)
    identity = sender[:authenticated_identity]

    identity.present? && op_identities.include?(identity) && op_commands.include?(command)
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
    !Server.up? || Preference.active_in_irc.to_i < 1 || (
      ServerQuery.numplayers.to_i < 1 &&
      Message::IrcReply.all.none? 
    )
  end
  
  def should_quit_irc?
    !Preference.irc_enabled? || @bot_started_at.nil? || @bot_started_at < 24.hours.ago
  end
  
  def twitch?
    !!(config[:nickserv_password].present? && config[:nickserv_password] =~ /^oauth/)
  end

  def extract_message_tags(message)
    return [{}, message] unless message.start_with?('@')

    raw_tags, untagged_message = message.split(' ', 2)
    tags = raw_tags.delete_prefix('@').split(';').to_h do |tag|
      key, value = tag.split('=', 2)
      [key, unescape_message_tag(value)]
    end

    [tags, untagged_message.to_s]
  end

  def unescape_message_tag(value)
    return nil if value.nil?

    escapes = {':' => ';', 's' => ' ', '\\' => '\\', 'r' => "\r", 'n' => "\n"}
    value.gsub(/\\(.)/) { escapes.fetch(Regexp.last_match(1), Regexp.last_match(1)) }
  end

  def sender_with_authenticated_identity(sender)
    tags = @current_message_tags.to_h.dup
    sender.merge(authenticated_identity: authenticated_identity(tags))
  end

  def authenticated_identity(tags)
    if twitch?
      return unless @enabled_capabilities.include?(TWITCH_TAGS_CAPABILITY)

      user_id = tags['user-id'].presence
      "twitch:#{user_id}" if user_id
    else
      return unless @enabled_capabilities.include?(IRC_ACCOUNT_CAPABILITY)

      account = tags['account'].presence
      "irc:#{account}" if account
    end
  end

  def desired_capabilities
    twitch? ? TWITCH_CAPABILITIES : [IRC_ACCOUNT_CAPABILITY]
  end

  def handle_capability_message(message)
    words = message.split(' ')
    subcommand = words[3]
    capabilities = message.split(' :', 2)[1].to_s.split

    case subcommand
    when 'LS'
      @available_capabilities.merge(capabilities)
      request_capabilities unless words[4] == '*'
    when 'ACK'
      @enabled_capabilities.merge(capabilities)
      finish_capability_negotiation
    when 'NAK'
      finish_capability_negotiation
    when 'NEW'
      @available_capabilities.merge(capabilities)
      request_new_capabilities(capabilities)
    when 'DEL'
      @available_capabilities.subtract(capabilities)
      @enabled_capabilities.subtract(capabilities)
    end
  end

  def request_capabilities
    requested = desired_capabilities & @available_capabilities.to_a

    if requested.any?
      response("CAP REQ :#{requested.join(' ')}")
    else
      finish_capability_negotiation
    end
  end

  def request_new_capabilities(capabilities)
    requested = desired_capabilities & capabilities
    response("CAP REQ :#{requested.join(' ')}") if requested.any?
  end

  def finish_capability_negotiation
    return if @cap_negotiation_complete

    response('CAP END')
    @cap_negotiation_complete = true
  end
end
