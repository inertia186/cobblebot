class ServerCallback::AnyPlayerEntry < ServerCallback
  def self.handle(line, options = {})
    return unless line =~ REGEX_PLAYER_CHAT_OR_EMOTE
    any_result = nil

    result = ServerCallback::PlayerChat.handle(line, options)
    any_result ||= result
    result = ServerCallback::PlayerEmote.handle(line, options)
    any_result ||= result

    if line =~ REGEX_PLAYER_CHAT
      segments = line.split(' ')
      player = segments[3].gsub(/[<>]+/, '')
      message = segments[4..-1].join(' ')
    elsif line =~ REGEX_PLAYER_EMOTE
      segments = line.split(' ')
      player = segments[4]
      message = segments[5..-1].join(' ')
    end

    ready.find_each do |callback|
      result = callback.handle_entry(player, message, line, options)
      any_result ||= result
    end
    
    any_result
  end
end