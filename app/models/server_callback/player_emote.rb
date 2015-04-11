class ServerCallback::PlayerEmote < ServerCallback
  def self.for_handling(line)
    line =~ REGEX_PLAYER_EMOTE
  end

  def self.entry(line, options)
    segments = line.split(' ')
    nick = segments[4]
    message = segments[5..-1].join(' ')

    [nick, message, line, options]    
  end
end