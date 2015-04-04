class Server
  def self.up?
    begin
      query = Query::simpleQuery(ServerProperties.server_ip, ServerProperties.server_port)
    rescue
      false
    end
    
    query.class == Hash
  end
  
  def self.latest_log_entry_at
    return unless up?
    
    server_log = "#{ServerProperties.path_to_server}/logs/latest.log"
    File.ctime(server_log)
  end
  
  def self.server_icon_path
    @server_icon_path ||= "#{ServerProperties.path_to_server}/server-icon.png"
  end

  def self.server_icon
    File.binread(server_icon_path) if File.exists? server_icon_path rescue return
  end
  
  def self.players
    result = ServerCommand.execute 'list'
    return Player.none unless !!result
    
    nicks = result.split(':')[1]

    return Player.none unless !!nicks

    Player.where(nick: nicks.split(", ")).order(:last_login_at)
  end
  
  def self.banned_players_file_path
    raise StandardError.new("Server Path not set.") if ServerProperties.path_to_server.nil?
    
    @banned_players_file_path ||= "#{ServerProperties.path_to_server}/banned-players.json"
  end

  def self.banned_players
    JSON[File.read banned_players_file_path] if File.exists? banned_players_file_path
  end

  def self.banned_ips_file_path
    raise StandardError.new("Server Path not set.") if ServerProperties.path_to_server.nil?
    
    @banned_ips_file_path ||= "#{ServerProperties.path_to_server}/banned-ips.json"
  end

  def self.banned_ips
    JSON[File.read banned_ips_file_path] if File.exists? banned_ips_file_path
  end

  def self.ops_file_path
    raise StandardError.new("Server Path not set.") if ServerProperties.path_to_server.nil?
    
    @ops_file_path ||= "#{ServerProperties.path_to_server}/ops.json"
  end

  def self.ops
    JSON[File.read ops_file_path] if File.exists? ops_file_path
  end

  def self.whitelist_file_path
    raise StandardError.new("Server Path not set.") if ServerProperties.path_to_server.nil?
    
    @whitelist_file_path ||= "#{ServerProperties.path_to_server}/whitelist.json"
  end

  def self.whitelist
    JSON[File.read whitelist_file_path] if File.exists? whitelist_file_path
  end
end