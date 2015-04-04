class MinecraftServerLogHandler
  REGEX_ANY = %r{^\[\d{2}:\d{2}:\d{2}\] .*$}
  REGEX_PLAYER_CHAT = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: <[^<]+> .*$}
  REGEX_PLAYER_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: \* [^<]+ .*$}
  REGEX_PLAYER_CHAT_OR_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: [\* ]*[ ]*[<]*[^<]+[>]* .*$}
  REGEX_USER_AUTHENTICATOR = %r{^\[\d{2}:\d{2}:\d{2}\] \[User Authenticator #\d+/INFO\]: .*$}
  
  def self.handle(line, options = {})
    begin
      Rails.logger.info "Handling: #{line}"

      result = handle_player_chat_or_emote(line, options)
      return !!result if !!result
      
      result = handle_any(line, options)
      return !!result if !!result
      
      result = handle_server_message(line, options)
      return !!result if !!result
    rescue StandardError => e
      Rails.logger.warn e
    end
    
    false
  end

  def self.execute_command(callback, nick, message, options = {})
    callback.update_attribute(:error_flag_at, nil)
    
    if callback.player_input?(message)
      begin
        message_escaped = message
      
        # TODO Also look for and escape: []\^$.|?*+()
        %w( [ ] \\ ^ $ . | ? * + \( \)).each do |c|
          message_escaped.gsub!(c, "\\#{c}")
        end
      
        # Find quotes to avoid breaking json.
        message_escaped.gsub!(/"/, '\"')
      
        # Find ruby escaped #{vars} in strings and just remove them.
        message_escaped.gsub!(/\#{[^}]+}/, '')

        pre_eval = nil
        eval("pre_eval = \"#{message_escaped}\"", Proc.new{}.binding)
        Rails.logger.warn "Possible problem with pre eval for messsage: \"#{message}\" became \"#{pre_eval}\"" unless message == pre_eval
        message = message_escaped
      rescue SyntaxError => e
        Rails.logger.error "Syntax error escaping message: #{e.inspect}"
      rescue StandardError => e
        Rails.logger.error "Problem escaping message: #{e.inspect}"
      end
    end
    
    command = callback.command.
      gsub("%message%", "#{message}").
      gsub("%nick%", "#{nick}").
      gsub("%cobblebot_version%", COBBLEBOT_VERSION)

    message.match(ServerCommand.eval_pattern(callback.pattern, callback.to_param)).captures.each_with_index do |capture, index|
      command.gsub!("%#{index + 1}%", "#{capture}")
    end if message.match(ServerCommand.eval_pattern(callback.pattern, callback.to_param))

    # Remove matched vars.
    command.gsub!(/%[^%]*%/, '')

    begin
      result = ServerCommand.eval_command(command, callback.to_param)
      # TODO clear the error flag
    rescue StandardError => e
      result = e.inspect
      callback.error_flag!
    end
    
    callback.ran!
    callback.update_attribute(:last_command_output, result.inspect)
  end
  
  def self.simulate_player_chat(nick, message)
    handle("[00:00:00] [Server thread/INFO]: <#{nick}> #{message}", pretend: true)
  end

  def self.simulate_server_message(message)
    handle("[00:00:00] [Server thread/INFO]: #{message}", pretend: true)
  end
private
  def self.handle_any(line, options = {})
    return unless line =~ REGEX_ANY
    any_result = nil

    segments = line.split(' ')
    message = segments[3..-1].join(' ')

    ServerCallback.ready.match_any.find_each do |callback|
      result = handle_message(callback, nil, message, line, options)
      any_result ||= !!result if !!result
    end
    
    !!any_result
  end

  def self.handle_server_message(line, options = {})
    return if line =~ REGEX_PLAYER_CHAT || line =~ REGEX_PLAYER_EMOTE
    any_result = nil

    if line =~ REGEX_USER_AUTHENTICATOR
      segments = line.split(' ')
      message = segments[4..-1].join(' ')
    else
      segments = line.split(' ')
      message = segments[3..-1].join(' ')
    end

    ServerCallback.ready.match_server_message.find_each do |callback|
      result = handle_message(callback, nil, message, line, options)
      any_result ||= !!result if !!result
    end
    
    !!any_result
  end

  def self.handle_player_chat(line, options = {})
    return unless line =~ REGEX_PLAYER_CHAT
    any_result = nil
    
    segments = line.split(' ')
    nick = segments[3].gsub(/[<>]+/, '')
    message = segments[4..-1].join(' ')
    
    ServerCallback.ready.match_player_chat.find_each do |callback|
      result = handle_message(callback, nick, message, line, options)
      any_result ||= !!result if !!result
    end
    
    !!any_result
  end

  def self.handle_player_emote(line, options = {})
    return unless line =~ REGEX_PLAYER_EMOTE
    any_result = nil
    
    segments = line.split(' ')
    nick = segments[4]
    message = segments[5..-1].join(' ')
    
    ServerCallback.ready.match_player_emote.find_each do |callback|
      result = handle_message(callback, nick, message, line, options)
      any_result ||= !!result if !!result
    end
    
    !!any_result
  end

  def self.handle_player_chat_or_emote(line, options = {})
    return unless line =~ REGEX_PLAYER_CHAT_OR_EMOTE
    any_result = nil

    result = handle_player_chat(line, options)
    any_result ||= !!result if !!result
    result = handle_player_emote(line, options)
    any_result ||= !!result if !!result

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
      result = handle_message(callback, player, message, line, options)
      any_result ||= !!result if !!result
    end
    
    !!any_result
  end

  def self.handle_message(callback, player, message, line, options = {})
    case message
    when ServerCommand.eval_pattern(callback.pattern, callback.to_param)
      execute_command(callback, player, message)
      callback.update_attribute(:last_match, line)
    end
  end
end