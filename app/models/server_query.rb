class ServerQuery
  def self.query
    query = Query::simpleQuery(ServerProperties.server_ip, ServerProperties.server_port)
    
    if query.class == Errno::ECONNREFUSED
      raise StandardError.new("Minecraft Server not started? #{query}")
    end
    
    query
  end

  def self.full_query
    full_query = Query::fullQuery(ServerProperties.server_ip, ServerProperties.server_port)

    if full_query.class == Errno::ECONNREFUSED
      raise StandardError.new("Minecraft Server not started? #{full_query}")
    end
    
    full_query
  end
  
  def self.method_missing(m, *args, &block)
    q = full_query
    
    super unless !!q

    return q[m] if q.keys.include?(m)

    super
  end
end
