class ServerCallback::ServerEntry < ServerCallback
  def self.handle(line, options = {})
    return if line =~ REGEX_PLAYER_CHAT || line =~ REGEX_PLAYER_EMOTE
    any_result = nil

    ready.find_each do |callback|
      result = callback.handle_entry(*entry(line, options))
      any_result ||= result
    end
    
    any_result
  end
private
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