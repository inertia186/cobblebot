class ServerCallback::PlayerChat < ServerCallback
  def self.handle(line, options = {})
    return unless line =~ REGEX_PLAYER_CHAT
    any_result = nil
    
    segments = line.split(' ')
    nick = segments[3].gsub(/[<>]+/, '')
    message = segments[4..-1].join(' ')
    
    ready.find_each do |callback|
      result = callback.handle_entry(nick, message, line, options)
      any_result ||= result
    end
    
    any_result
  end
end