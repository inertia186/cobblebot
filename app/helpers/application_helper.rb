require 'rcon/rcon'

module ApplicationHelper
  def server_properties_path
    raise StandardError.new("Preference.path_to_server not initialized properly") if Preference.path_to_server.nil?
    raise StandardError.new("expected valid path to server: #{Preference.path_to_server}") if !File.directory?(Preference.path_to_server)
    
    Preference.path_to_server + "/" + 'server.properties'
  end
  
  def server_properties
    @server_properties ||= JavaProperties::Properties.new(server_properties_path)
  end
  
  def query
    query ||= Query::simpleQuery(server_properties['server-ip'], server_properties['server-port'])
  end
  
  def rcon
    raise StandardError.new("RCON port not set.  To set, please modify server.properties and change rcon.port=25575") unless server_properties['rcon.port']
    raise StandardError.new("RCON password not set.  To set, please modify server.properties and change rcon.password=") unless server_properties['rcon.password']
    raise StandardError.new("RCON is disabled.  To enable rcon, please modify server.properties and change enable-rcon=false to enable-rcon=true and restart server.") unless server_properties['enable-rcon'] == 'true'

    rcon ||= RCON::Minecraft.new(server_properties['server-ip'], server_properties['rcon.port'])
    rcon.auth(server_properties['rcon.password'])
    
    rcon
  end
  
  def say message
    rcon.command "tellraw @a {\"color\": \"white\", \"text\":\"[Server] #{message}\"}"
  end
end
