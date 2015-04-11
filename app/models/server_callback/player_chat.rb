class ServerCallback::PlayerChat < ServerCallback
  def self.for_handling(line)
    line =~ REGEX_PLAYER_CHAT
  end

  def self.entry(line, options)
    segments = line.split(' ')
    nick = segments[3].gsub(/[<>]+/, '')
    message = segments[4..-1].join(' ')
  
    [nick, message, line, options]
  end
end