include ApplicationHelper

class MinecraftServerLogHandler
  REGEX_ANY = %r{^\[\d{2}:\d{2}:\d{2}\] .*$}
  REGEX_PLAYER_CHAT = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: <[^<]+> .*$}
  REGEX_PLAYER_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: \* [^<]+ .*$}
  REGEX_PLAYER_CHAT_OR_EMOTE = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/INFO\]: [\* ]*[ ]*[<]*[^<]+[>]* .*$}
  
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

  def self.execute_command(callback, player, message)
    if message =~ eval(callback.pattern)
#      Rails.logger.info "Match Executing: #{callback.inspect} :: #{command.inspect}"
    else
#      Rails.logger.info "Force Executing: #{callback.inspect} :: #{command.inspect}"
    end
    
    command = callback.command.
      gsub("%1%", "#{$1}").
      gsub("%2%", "#{$2}").
      gsub("%3%", "#{$3}").
      gsub("%4%", "#{$4}").
      gsub("%5%", "#{$5}").
      gsub("%6%", "#{$6}").
      gsub("%7%", "#{$7}").
      gsub("%8%", "#{$8}").
      gsub("%9%", "#{$9}").
      gsub("%message%", "#{message}").
      gsub("%player%", "#{player}").
      gsub("%cobblebot_version%", COBBLEBOT_VERSION)
    
    begin
      result = eval(command)
    rescue StandardError => e
      result = e.inspect
    end
    
    callback.ran!
    callback.update_attribute(:last_command_output, result)
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

    segments = line.split(' ')
    message = segments[3..-1].join(' ')

    ServerCallback.ready.match_server_message.find_each do |callback|
      handle_message(callback, nil, message, line)
    end
  end

  def self.handle_player_chat(line)
    return unless line =~ REGEX_PLAYER_CHAT

    segments = line.split(' ')
    player = segments[3].gsub(/[<>]+/, '')
    message = segments[4..-1].join(' ')
    
    ServerCallback.ready.match_player_chat.find_each do |callback|
      handle_message(callback, player, message, line)
    end
  end

  def self.handle_player_emote(line)
    return unless line =~ REGEX_PLAYER_EMOTE
    
    segments = line.split(' ')
    player = segments[4]
    message = segments[5..-1].join(' ')
    
    ServerCallback.ready.match_player_emote.find_each do |callback|
      handle_message(callback, player, message, line)
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
    when eval(callback.pattern)
      execute_command(callback, player, message)
      callback.update_attribute(:last_match, line)
    end
  end
end