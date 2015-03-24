class MinecraftServerLogHandler
  REGEX_ANY = %r{^\[\d{2}:\d{2}:\d{2}\] .*$}
  REGEX_PLAYER_CHAT = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: <[^<]+> .*$}
  REGEX_PLAYER_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: \* [^<]+ .*$}
  REGEX_PLAYER_CHAT_OR_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: [\* ]*[ ]*[<]*[^<]+[>]* .*$}
  REGEX_USER_AUTHENTICATOR = %r{^\[\d{2}:\d{2}:\d{2}\] \[User Authenticator #\d+/INFO\]: .*$}
  
  def self.handle(line)
    begin
      Rails.logger.info "Handling: #{line}"

      handle_player_chat_or_emote(line)
      handle_any(line)
      handle_server_message(line)
    rescue StandardError => e
      Rails.logger.warn e
    end
  end

  def self.execute_command(callback, nick, message)
    callback.update_attribute(:error_flag_at, nil)
    
    begin
      # TODO Escape problem substrings like quotes and double-check selectors
      # don't matter in tellraw bodies.
      message_escaped = message.gsub(/"/, '\"')
      message_escaped = message_escaped.gsub(/\#{[^}]+}/, '')

      pre_eval = nil
      eval("pre_eval = \"#{message_escaped}\"")
      Rails.logger.warn "Possible problem with pre eval for messsage: \"#{message}\" became \"#{pre_eval}\"" unless message == pre_eval
      message = message_escaped
    rescue StandardError => e
      Rails.logger.error "Problem escaping message: #{e.inspect}"
    end
    
    command = callback.command.
      gsub("%message%", "#{message}").
      gsub("%nick%", "#{nick}").
      gsub("%cobblebot_version%", COBBLEBOT_VERSION)

    message.match(ServerCommand.eval_pattern(callback.pattern)).captures.each_with_index do |capture, index|
      command.gsub!("%#{index + 1}%", "#{capture}")
    end if message.match(ServerCommand.eval_pattern(callback.pattern))

    # Remove matched vars.
    command.gsub!(/%[^%]*%/, '')

    begin
      result = ServerCommand.eval_command(command)
      # TODO clear the error flag
    rescue StandardError => e
      result = e.inspect
      callback.error_flag!
    end
    
    callback.ran!
    callback.update_attribute(:last_command_output, result.inspect)
  end
private
  def self.handle_any(line)
    return unless line =~ REGEX_ANY

    segments = line.split(' ')
    message = segments[3..-1].join(' ')

    ServerCallback.ready.match_any.find_each do |callback|
      handle_message(callback, nil, message, line)
    end
  end

  def self.handle_server_message(line)
    return if line =~ REGEX_PLAYER_CHAT || line =~ REGEX_PLAYER_EMOTE

    if line =~ REGEX_USER_AUTHENTICATOR
      segments = line.split(' ')
      message = segments[4..-1].join(' ')
    else
      segments = line.split(' ')
      message = segments[3..-1].join(' ')
    end

    ServerCallback.ready.match_server_message.find_each do |callback|
      handle_message(callback, nil, message, line)
    end
  end

  def self.handle_player_chat(line)
    return unless line =~ REGEX_PLAYER_CHAT

    segments = line.split(' ')
    nick = segments[3].gsub(/[<>]+/, '')
    message = segments[4..-1].join(' ')
    
    ServerCallback.ready.match_player_chat.find_each do |callback|
      handle_message(callback, nick, message, line)
    end
  end

  def self.handle_player_emote(line)
    return unless line =~ REGEX_PLAYER_EMOTE
    
    segments = line.split(' ')
    nick = segments[4]
    message = segments[5..-1].join(' ')
    
    ServerCallback.ready.match_player_emote.find_each do |callback|
      handle_message(callback, nick, message, line)
    end
  end

  def self.handle_player_chat_or_emote(line)
    return unless line =~ REGEX_PLAYER_CHAT_OR_EMOTE

    handle_player_chat(line)
    handle_player_emote(line)

    if line =~ REGEX_PLAYER_CHAT
      segments = line.split(' ')
      player = segments[3].gsub(/[<>]+/, '')
      message = segments[4..-1].join(' ')
    elsif line =~ REGEX_PLAYER_EMOTE
      segments = line.split(' ')
      player = segments[4]
      message = segments[5..-1].join(' ')
    end

    ServerCallback.ready.match_player_chat_or_emote.find_each do |callback|
      handle_message(callback, player, message, line)
    end
  end

  def self.handle_message(callback, player, message, line)
    case message
    when ServerCommand.eval_pattern(callback.pattern)
      execute_command(callback, player, message)
      callback.update_attribute(:last_match, line)
    end
  end
end