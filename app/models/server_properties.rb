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
    return super unless !!properties

    keys = properties.keys
    key = m.to_s.dasherize.to_sym

    return properties[key] if keys.include? key
    return properties[dotted m] if dotted? m
    return properties[unquestioned m] == 'true' if unquestioned? m
    return properties[unquestioned_dotted m] == 'true' if unquestioned_dotted? m

    super
  end
private
  def self.dotted?(m)
    properties.keys.include? dotted m
  end

  def self.dotted(m)
    m.to_s.gsub(/_/, '.').to_sym
  end

  def self.unquestioned?(m)
    properties.keys.include? unquestioned m
  end
  
  def self.unquestioned(m)
    m.to_s.dasherize.gsub(/\?$/, '').to_sym
  end

  def self.unquestioned_dotted?(m)
    properties.keys.include? unquestioned_dotted m
  end
  
  def self.unquestioned_dotted(m)
    dotted m.to_s.gsub(/\?$/, '').to_sym
  end
end
