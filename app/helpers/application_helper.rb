require 'rcon/rcon'

module ApplicationHelper
  def server_properties_path
    raise StandardError.new("Preference.path_to_server not initialized properly") if Preference.path_to_server.nil?
    raise StandardError.new("expected valid path to server: #{Preference.path_to_server}") if !File.directory?(Preference.path_to_server)
    
    Preference.path_to_server + "/" + 'server.properties'
  end
  
  def active_nav nav
    return :active if controller_name == nav
  end
  
  def server_properties
    @server_properties ||= JavaProperties::Properties.new(server_properties_path)
  end
  
  def query
    query ||= Query::simpleQuery(server_properties['server-ip'], server_properties['server-port'])
  end

  def full_query
    full_query ||= Query::fullQuery(server_properties['server-ip'], server_properties['server-port'])
  end
  
  def rcon
    raise StandardError.new("RCON port not set.  To set, please modify server.properties and change rcon.port=25575") unless server_properties['rcon.port']
    raise StandardError.new("RCON password not set.  To set, please modify server.properties and change rcon.password=") unless server_properties['rcon.password']
    raise StandardError.new("RCON is disabled.  To enable rcon, please modify server.properties and change enable-rcon=false to enable-rcon=true and restart server.") unless server_properties['enable-rcon'] == 'true'

    5.times do
      rcon ||= RCON::Minecraft.new(server_properties['server-ip'], server_properties['rcon.port'])

      begin
        return rcon if rcon.auth(server_properties['rcon.password'])
      rescue Errno::ECONNREFUSED => e
        Rails.logger.warn e.inspect
        sleep 5
        rcon = nil
      end
    end
    
    nil
  end
  
  ## Simuates /say
  def say message
    rcon.command "tellraw @a {\"color\": \"white\", \"text\":\"[Server] #{message}\"}"
  end

  ## Simuates /tell
  def tell player, message
    rcon.command "tellraw #{player} {\"color\": \"gray\", \"text\":\"Server whispers to you: #{message}\"}"
  end

  ## Renders a hyperlink.
  def link player, link
    text = link.gsub(/http/i, 'http')
    link = text.split('http')[1]
    return unless link

    link = "http#{link.split(' ')[0]}"
    return unless !!link.split('://')[1]
    
    begin
      agent = Mechanize.new
      agent.keep_alive = false
      agent.open_timeout = 5
      agent.read_timeout = 5
      agent.get link
    
      title = if agent.page && defined?(agent.page.title) && agent.page.title 
        "#{link.split('/')[2]} :: #{agent.page.title.strip}"
      else
        link
      end
    rescue SocketError => e
      Rails.logger.warn "Ignoring link: #{link}" && return
    rescue Net::OpenTimeout => e
      title = link
    rescue Net::HTTP::Persistent::Error => e
      title = link
    rescue StandardError => e
      title = "#{link.split('/')[2]} :: #{e.inspect}"
    end

    original_title = title
    title = title.gsub(/[^a-zA-Z0-9:?&=#@+*, \.\/\"\[\]\(\)]/, '-').truncate(90)
    Rails.logger.warn "Removed characters from: #{original_title}" if title != original_title # FIXME Remove later.
  
    rcon.command "tellraw #{player} {\"text\":\"\",\"extra\":[{\"text\":\"#{title}\",\"color\":\"dark_purple\",\"underlined\":\"true\",\"clickEvent\":{\"action\":\"open_url\",\"value\":\"#{link}\"}}]}"
  end
  
  def tell_motd player
    return unless !!Preference.motd
    
    rcon.command "tellraw #{player} {\"text\":\"\",\"extra\":[{\"text\":\"Message of the Day\",\"color\":\"green\"}]}"
    rcon.command "tellraw #{player} {\"text\":\"\",\"extra\":[{\"text\":\"===\",\"color\":\"green\"}]}"

    Preference.motd.split("\n").each do |line|
      rcon.command "tellraw #{player} {\"text\":\"\",\"extra\":[{\"text\":\"#{line}\",\"color\":\"green\"}]}"
    end
  end
end
