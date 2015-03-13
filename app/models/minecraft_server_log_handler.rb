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
private
  def self.handle_any(line)
    return unless line =~ REGEX_ANY

    segments = line.split(' ')
    message = segments[3..-1].join(' ')

    ServerCallback.enabled.match_any.find_each do |callback|
      handle_message(callback, nil, message)
    end
  end

  def self.handle_server_message(line)
    return if line =~ REGEX_PLAYER_CHAT || line =~ REGEX_PLAYER_EMOTE

    segments = line.split(' ')
    message = segments[3..-1].join(' ')
    
    ServerCallback.enabled.match_server_message.find_each do |callback|
      handle_message(callback, nil, message)
    end
  end

  def self.handle_player_chat(line)
    return unless line =~ REGEX_PLAYER_CHAT

    segments = line.split(' ')
    player = segments[3].gsub(/[<>]+/, '')
    message = segments[4..-1].join(' ')
    
    ServerCallback.enabled.match_player_chat.find_each do |callback|
      handle_message(callback, player, message)
    end
  end

  def self.handle_player_emote(line)
    return unless line =~ REGEX_PLAYER_EMOTE
    
    segments = line.split(' ')
    player = segments[4]
    message = segments[5..-1].join(' ')
    
    ServerCallback.enabled.match_player_emote.find_each do |callback|
      handle_message(callback, player, message)
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

    ServerCallback.enabled.match_player_chat_or_emote.find_each do |callback|
      handle_message(callback, player, message)
    end
  end

  def self.handle_message(callback, player, message)
    case message
    when eval(callback.pattern)
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
        gsub("%message%", "#{message}")
      Rails.logger.info "Executing: #{callback.inspect} :: #{command.inspect}"
      eval(command)
    end
  end
end