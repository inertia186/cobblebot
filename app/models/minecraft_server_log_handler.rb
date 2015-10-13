class MinecraftServerLogHandler
  REGEX_RCON_LISTENER = %r{^\[\d{2}:\d{2}:\d{2}\] \[RCON Listener #[0-9]+/INFO\]: .*$}
  REGEX_RCON_CLIENT = %r{^\[\d{2}:\d{2}:\d{2}\] \[RCON Client #[0-9]+/INFO\]: .*$}
  REGEX_NON_LOG_EVENT = %r{^(?!\[\d{2}:\d{2}:\d{2}\]).*$}
  REGEX_DUPLICATE_UUID_WARNING = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/WARN\]: Tried to add entity [^ ]+ with pending removal and duplicate UUID [0-9a-fA-F\-]+$}
  REGEX_VEHICLE_WARNING = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/WARN\]: [^ ]+ \(vehicle of [^ ]+\) moved too quickly! [\-0-9\.]+,[\-0-9\.]+,[\-0-9\.]+$}
  REGEX_KEEPING_ENTITY_WARNING = %r{^\[\d{2}:\d{2}:\d{2}\] \[Server thread\/WARN\]: Keeping entity [^ ]+ that already exists with UUID [0-9a-fA-F\-]+$}
  ALL_REGEX_IGNORE = [
    REGEX_RCON_LISTENER, REGEX_RCON_CLIENT, REGEX_NON_LOG_EVENT,
    REGEX_DUPLICATE_UUID_WARNING, REGEX_VEHICLE_WARNING,
    REGEX_KEEPING_ENTITY_WARNING
  ]
  
  def self.ignore?(line, options = {})
    Regexp.union(ALL_REGEX_IGNORE).match(line)
  end
  
  def self.handle(line, options = {})
    return if ignore?(line, options)
    
    begin
      Rails.logger.info "Handling: #{line}"
      any_result = nil
      types = [ServerCallback::AnyPlayerEntry, ServerCallback::AnyEntry, ServerCallback::ServerEntry]

      types.each do |c|
        result = c.handle(line, options)
        any_result ||= result
      end

      return true if !!any_result
    rescue StandardError => e
      Rails.logger.warn e
    end
    
    false
  end

  def self.simulate_player_chat(nick, message)
    handle("[00:00:00] [Server thread/INFO]: <#{nick}> #{message}", pretend: true)
  end

  def self.simulate_server_message(message)
    handle("[00:00:00] [Server thread/INFO]: #{message}", pretend: true)
  end
end