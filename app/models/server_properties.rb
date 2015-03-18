class ServerProperties
  cattr_accessor :path
  
  def self.reset_vars
    @path_to_server = nil
    @path = nil
    @properties = nil
  end
  
  def self.path_to_server
    return @path_to_server unless @path_to_server.nil?
    
    path_to_server = Preference.path_to_server
    raise StandardError.new("Preference.path_to_server not initialized properly") if path_to_server.nil?
    raise StandardError.new("Expected valid path to server: #{path_to_server}") if !File.directory?(path_to_server)

    @path_to_server ||= path_to_server
  end
  
  def self.path
    @path ||= path_to_server + "/" + 'server.properties'
  end

  def self.level_name
    begin
      properties['level-name'] || '???'
    rescue
      reset_vars
      '???'
    end
  end
  
  def self.properties
    @properties = nil if @properties_ctime.nil? || @properties_ctime != File.ctime(path)
    @properties_ctime = File.ctime(path)
    @properties ||= JavaProperties::Properties.new(path)
  end
  
  def self.keys_as_strings
    properties.keys.map(&:to_s)
  end
  
  def self.method_missing(m, *args, &block)
    super unless !!properties

    keys = properties.keys
    key = m.to_s.dasherize.to_sym
    dotted_key = m.to_s.gsub(/_/, '.').to_sym
    unquestioned_key = m.to_s.dasherize.gsub(/\?$/, '').to_sym
    unquestioned_dotted_key = m.to_s.gsub(/_/, '.').gsub(/\?$/, '').to_sym

    if keys.include?(key)
      return properties[key]
    elsif keys.include?(dotted_key)
      return properties[dotted_key]
    elsif keys.include?(unquestioned_key)
      return properties[unquestioned_key] == 'true'
    elsif keys.include?(unquestioned_dotted_key)
      return properties[unquestioned_dotted_key] == 'true'
    end

    super
  end
end
