class MinecraftServerLogHandler
  def self.handle(line, options = {})
    begin
      Rails.logger.info "Handling: #{line}"
      any_result = nil

      result = ServerCallback::AnyPlayerEntry.handle(line, options)
      any_result ||= result
      result = ServerCallback::AnyEntry.handle(line, options)
      any_result ||= result
      result = ServerCallback::ServerEntry.handle(line, options)
      any_result ||= result

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