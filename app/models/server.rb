class Server
  def self.players
    result = ServerCommand.execute 'list'
    return Player.none unless !!result
    
    nicks = result.split(':')[1]

    return Player.none unless !!nicks

    Player.where(nick: nicks.split(", ")).order(:last_login_at)
  end
end