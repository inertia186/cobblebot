class Server
  def self.players
    result = ServerCommand.execute 'list'
    nicks = result.split(':')[1]

    return Player.none unless !!nicks

    Player.where(nick: nicks.split(", ")).order(:updated_at)
  end
end