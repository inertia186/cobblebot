class ServerCallback::ServerEntry < ServerCallback
  def self.for_handling(line)
    !(line =~ REGEX_PLAYER_CHAT || line =~ REGEX_PLAYER_EMOTE)
  end
  
  def self.entry(line, options)
    if line =~ REGEX_USER_AUTHENTICATOR
      segments = line.split(' ')
      message = segments[4..-1].join(' ')
    else
      segments = line.split(' ')
      message = segments[3..-1].join(' ')
    end

    [nil, message, line, options]    
  end
end