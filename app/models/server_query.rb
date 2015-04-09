class ServerQuery
  TRY_MAX = 5
  RETRY_SLEEP = 5

  def self.try_max
    Rails.env == 'test' ? 1 : TRY_MAX
  end
  
  def self.retry_sleep
    Rails.env == 'test' ? 0 : RETRY_SLEEP
  end
  
  def self.query
    query = nil
    
    try_max.times do
      begin
        query = Query::simpleQuery(ServerProperties.server_ip, ServerProperties.server_port)
    
        if query.class == Errno::ECONNREFUSED
          raise StandardError.new("Minecraft Server not started? #{query}")
        end
      rescue StandardError => e
        Rails.logger.warn e.inspect
        sleep retry_sleep
        ServerProperties.reset_vars
      end
    end
    
    query
  end

  def self.full_query
    full_query = nil
    
    try_max.times do
      begin
        full_query = Query::fullQuery(ServerProperties.server_ip, ServerProperties.server_port)
      rescue StandardError => e
        Rails.logger.warn e.inspect
        sleep retry_sleep
        ServerProperties.reset_vars
      end
    end

    if full_query.class != Hash
      ServerProperties.reset_vars
      ServerCommand.reset_vars
      
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
