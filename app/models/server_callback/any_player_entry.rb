class ServerCallback::AnyPlayerEntry < ServerCallback
  def self.for_handling(line)
    line =~ REGEX_PLAYER_CHAT_OR_EMOTE
  end

  def self.handle(line, options = {})
    return unless for_handling(line)
    any_result = nil

    [ServerCallback::PlayerChat, ServerCallback::PlayerEmote].each do |c|
      result = c.handle(line, options)
      any_result ||= result
    end

    result = super(line, options)
    any_result ||= result
    
    any_result
  end
private
  def self.entry(line, options)
    if line =~ REGEX_PLAYER_CHAT
      segments = line.split(' ')
      player = segments[3].gsub(/[<>]+/, '')
      message = segments[4..-1].join(' ')
    elsif line =~ REGEX_PLAYER_EMOTE
      segments = line.split(' ')
      player = segments[4]
      message = segments[5..-1].join(' ')
    end
    
    [player, message, line, options]
  end
end