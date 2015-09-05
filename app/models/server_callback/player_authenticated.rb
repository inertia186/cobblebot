class ServerCallback::PlayerAuthenticated < ServerCallback::ServerEntry
  def self.for_handling(line)
    line =~ REGEX_PLAYER_AUTHENTICATED
  end
  
  def self.entry(line, options)
    segments = line.split(' ')
    nick = segments[7]
    message = segments[4..-1].join(' ')

    [nick, message, line, options]    
  end
end
