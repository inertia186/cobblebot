require 'rcon/rcon'

class Server
  TRY_MAX = 5
  RETRY_SLEEP = 5
  
  @@mock_options = nil

  def self.mock_mode(options = {}, &block)
    raise "Mock mode should only be used in tests." unless Rails.env == 'test'
    
    @@mock_options = options
    yield
    @@mock_options = nil
  end
  
  def self.try_max
    Rails.env == 'test' ? 1 : Preference.try_max.to_i || TRY_MAX
  end
  
  def self.retry_sleep
    Rails.env == 'test' ? 0 : RETRY_SLEEP
  end
  
  def self.up?
    return @@mock_options[:up] if !!@@mock_options
    
    query = nil
    
    try_max.times do
      begin
        query = Query::simpleQuery(ServerProperties.server_ip, ServerProperties.server_port)
        unless query.class == Hash
          raise CobbleBotError.new(message: 'Connection refused.', cause: query)
        end
        break
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
    return @@mock_options[:latest_log_entry_at] if !!@@mock_options
    
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
    return @@mock_options[:player_nicks] if !!@@mock_options
    
    nicks = []
    
    return nicks unless up?
    
    if !!selector
      result = ServerCommand.execute("entitydata #{selector} {}")
      if result =~ / is a player and cannot be changed/
        nicks = result.split(' is a player and cannot be changed')
      end
    else
      nicks = begin
        ServerQuery.full_query[:players]
      rescue
        result = ServerCommand.execute 'list'
        n = result.split(':')[1] if !!result
        n.split(', ') if !!n
      end
    end

    nicks ||= []
  end
  
  # Experimental entity data lookup.
  #
  # The intention of this method is to return all entity data currently loaded
  # in memory.
  #
  # Getting this data through RCON is problematic because often the return
  # value is greater than 4096 bytes, so multiple read attempts must be made
  # until the buffer is empty.
  #
  def self.entity_data(options = {selector: "@e[c=1]", near_player: nil, radius: 0, only: []})
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
      raise CobbleBotError.new(message: "Unable to find #{player.nick} position.") unless !!pos
      
      "@e[r=#{radius},x=#{pos[0].to_i},y=#{pos[1].to_i},z=#{pos[2].to_i}]"
    elsif !!options[:only_type]
      s = '@e['
      if options[:only_type].class == Array
        # FIXME This actually does not work.  Only the last type added to the selector will be recognized. See: http://gaming.stackexchange.com/questions/166679/how-do-i-select-two-types-of-entities-in-minecraft-with-the-type-selector
        options[:only_type].each do |type|
          s += ',' unless s == '@e['
          s += "type=#{type}"
        end
      else
        s += "type=#{options[:only_type]}"
      end
      
      s += ']'
    elsif !!options[:except_type]
      s = '@e['
      if options[:except_type].class == Array
        # FIXME See above fixme for why this doesn't work.
        options[:except_type].each do |type|
          s += ',' unless s == '@e['
          s += "type=!#{type}"
        end
      else
        s += "type=!#{options[:except_type]}"
      end
      
      s += ']'
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
    only = options[:only]
    
    if !!only && only.any?
      _entities = []

      only.each do |o|
        case o
        when :nether
          _entities += entities.select { |data| data =~ /Dimension:-1,/ }
        when :overworld
          _entities += entities.select { |data| data =~ /Dimension:0,/ }
        when :end
          _entities += entities.select { |data| data =~ /Dimension:1,/ }
        end
      end
      
      entities = _entities
    end

    entities
  end
  
  def self.loaded_items
    result = {}
    data = Server.entity_data(selector: '@e[type=Item]')
    
    data.map do |i|
      i.split('Item:{id:"')[1].to_s.split('"')[0]
    end.reject(&:nil?).uniq.each do |id|
      nc = data.map do |j|
        j.split(/Dimension:-1,.*Item:{id:"#{id}/)[1]
      end.reject(&:nil?).reject(&:empty?).size

      oc = data.map do |j|
        j.split(/Dimension:0,.*Item:{id:"#{id}/)[1]
      end.reject(&:nil?).reject(&:empty?).size
      
      ec = data.map do |j|
        j.split(/Dimension:1,.*Item:{id:"#{id}/)[1]
      end.reject(&:nil?).reject(&:empty?).size
      
      c = data.map do |j|
        j.split("Item:{id:\"#{id}")[1].to_s.split('"')[1]
      end.reject(&:nil?).reject(&:empty?).size

      result[id.split(':').last.to_sym] = {
        nether_count: nc, overworld_count: oc, end_count: ec, total_count: c, 
      }
    end
    
    result
  end
  
  def self.players(selector = nil)
    return Player.none unless (nicks = player_nicks(selector)).any?

    Player.where(nick: nicks).order(:last_login_at)
  end
  
  def self.file_path(file_name)
    raise CobbleBotError.new(message: "Server Path not set.") if ServerProperties.path_to_server.nil?
    
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

  def self.latest_debug_report_path
    debug_path = file_path 'debug'
    
    Dir.glob("#{debug_path}/*.txt").sort.last
  end
  
  def self.latest_debug_report
    File.read latest_debug_report_path if File.exists? latest_debug_report_path
  end

  # To get the full list of votes.
  def self.mmp_votes
    url = "http://minecraft-mp.com/api/?object=servers&element=votes&key=#{Preference.mmp_api_key}&format=json"
    response = Net::HTTP.get_response(URI.parse(url))
    json = JSON.parse(response.body)
  end

  # To get the full detail of this server.  
  def self.mmp_status
    url = "http://minecraft-mp.com/api/?object=servers&element=detail&key=#{Preference.mmp_api_key}"
    response = Net::HTTP.get_response(URI.parse(url))
    json = JSON.parse(response.body)
  end
end