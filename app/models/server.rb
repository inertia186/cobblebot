require 'rcon/rcon'

class Server
  TRY_MAX = 5
  RETRY_SLEEP = 5

  def self.try_max
    Rails.env == 'test' ? 1 : TRY_MAX
  end
  
  def self.retry_sleep
    Rails.env == 'test' ? 0 : RETRY_SLEEP
  end
  
  def self.up?
    query = nil
    
    try_max.times do
      begin
        query = Query::simpleQuery(ServerProperties.server_ip, ServerProperties.server_port)
      rescue StandardError => e
        Rails.logger.warn e.inspect
        sleep retry_sleep
        ServerProperties.reset_vars
        @file_paths = nil
      end
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
  #
  # The intention of this method is to return all entity data currently loaded
  # in memory.
  #
  # Unfortunately, it only returns entity data for the overworld.  Getting
  # this data through RCON is problematic because often the return value is
  # greater than 4096 bytes, so multiple read attempts must be made until the
  # buffer is empty.
  #
  def self.entity_data(options = {selector: "@e[c=1]", near_player: nil, radius: 0})
    end_response = 'Unknown command. Try /help for a list of commands'
    error_response = 'The entity UUID provided is in an invalid format'
    rcon = RCON::Minecraft.new(ServerProperties.server_ip, ServerProperties.rcon_port)
    rcon.auth(ServerProperties.rcon_password)
    response = []
    
    selector = if !!options[:selector]
      options[:selector]
    elsif !!options[:near_player] && !!options[:radius]
      radius = options[:radius]
      player = options[:near_player]
      player = Player.find_by_nick player if player.class == String
      
      pos = player.current_location
      raise "Unable to find #{player.nick} position." unless !!pos
      
      "@e[r=#{radius},x=#{pos[0].to_i},y=#{pos[1].to_i},z=#{pos[2].to_i}]"
    end

    response << rcon.command("entitydata #{selector} {}")
    begin
      response << r = rcon.command('') until r == end_response
    rescue StandardError => e
      Rails.logger.warn "#{self} :: #{e.inspect}"
    end
    response -= [end_response]
    response -= [error_response]

    response = response.map do |r|
      r unless r =~ /.* is a player and cannot be changed/
    end

    rcon.disconnect
    
    entities = response.join.split('The data tag did not change: ').reject(&:empty?)
  end
  
  def self.players(selector = nil)
    return Player.none unless (nicks = player_nicks(selector)).any?

    Player.where(nick: nicks).order(:last_login_at)
  end
  
  def self.file_path(file_name)
    raise StandardError.new("Server Path not set.") if ServerProperties.path_to_server.nil?
    
    @file_paths ||= {}
    @file_paths[file_name.to_sym] ||= "#{ServerProperties.path_to_server}/#{file_name}"
  end
  
  def self.banned_players_file_path
    file_path 'banned-players.json'
  end

  def self.banned_players
    JSON[File.read banned_players_file_path] if File.exists? banned_players_file_path
  end

  def self.banned_ips_file_path
    file_path 'banned-ips.json'
  end

  def self.banned_ips
    JSON[File.read banned_ips_file_path] if File.exists? banned_ips_file_path
  end

  def self.ops_file_path
    file_path 'ops.json'
  end

  def self.ops
    JSON[File.read ops_file_path] if File.exists? ops_file_path
  end

  def self.whitelist_file_path
    file_path 'whitelist.json'
  end

  def self.whitelist
    JSON[File.read whitelist_file_path] if File.exists? whitelist_file_path
  end
end