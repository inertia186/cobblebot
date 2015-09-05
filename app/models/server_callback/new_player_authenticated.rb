class ServerCallback::NewPlayerAuthenticated < ServerCallback::PlayerAuthenticated
  def self.for_handling(line)
    return false unless line =~ REGEX_PLAYER_AUTHENTICATED
    
    segments = line.split(' ')
    uuid = segments[9]
    
    Player.newly_created.where(uuid: uuid).any?
  end
end
