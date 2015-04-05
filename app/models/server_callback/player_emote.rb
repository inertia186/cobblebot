class ServerCallback::PlayerEmote < ServerCallback
  def self.handle(line, options = {})
    return unless line =~ REGEX_PLAYER_EMOTE
    any_result = nil
    
    segments = line.split(' ')
    nick = segments[4]
    message = segments[5..-1].join(' ')
    
    ready.find_each do |callback|
      result = callback.handle_entry(nick, message, line, options)
      any_result ||= result
    end
    
    any_result
  end
end