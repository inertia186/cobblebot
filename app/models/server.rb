require 'rcon/rcon'

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
  
  def self.player_nicks(selector = nil)
    nicks = []
    
    if !!selector
      result = ServerCommand.execute("entitydata #{selector} {}")
      if result =~ / is a player and cannot be changed/
        nicks = result.split(' is a player and cannot be changed')
      end
    else
      result = ServerCommand.execute 'list'
      n = result.split(':')[1] if !!result
      nicks = n.split(', ') if !!n
    end

    nicks ||= []
  end
  
  # Experimental entity data lookup.
  def self.entity_data(selector = "@e[c=1]")
    end_response = 'Unknown command. Try /help for a list of commands'
    rcon = RCON::Minecraft.new(ServerProperties.server_ip, ServerProperties.rcon_port)
    rcon.auth(ServerProperties.rcon_password)
    response = []
    
    response << rcon.command("entitydata #{selector} {}")
    begin
      response << r = rcon.command('') until r == end_response
    rescue StandardError => e
      Rails.logger.warn "#{self} :: #{e.inspect}"
    end
    response -= [end_response]

    rcon.disconnect
    
    entities = response.join.split('The data tag did not change: ').reject(&:empty?)
  end
  
  def self.players(selector = nil)
    return Player.none unless (nicks = player_nicks(selector)).any?

    Player.where(nick: nicks).order(:last_login_at)
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