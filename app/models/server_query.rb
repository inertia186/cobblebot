class ServerQuery
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
    Rails.env == 'test' ? 1 : TRY_MAX
  end
  
  def self.retry_sleep
    Rails.env == 'test' ? 0 : RETRY_SLEEP
  end
  
  def self.query(method = :simpleQuery)
    return @@mock_options[:query] if !!@@mock_options
    return @@mock_options[:full_query] if !!@@mock_options
    
    query = nil
  
    try_max.times do
      begin
        query = Query.send(method, ServerProperties.server_ip, ServerProperties.server_port)

        if query.class != Hash
          ServerProperties.reset_vars
          ServerCommand.reset_vars
        end
        
        break
      rescue StandardError => e
        Rails.logger.warn e.inspect
        sleep retry_sleep
        ServerProperties.reset_vars
      end
      
      break
    end

    raise CobbleBotError.new(message: "Minecraft Server not started? #{query}") if query.class != Hash

    query
  end

  def self.full_query
    query(:fullQuery)
  end
  
  def self.method_missing(m, *args, &block)
    q = if !!@@mock_options && @@mock_options[:full_query]
      @@mock_options[:full_query]
    else
      full_query
    end
    
    super unless !!q

    return q[m] if q.keys.include?(m)

    super
  end
end
