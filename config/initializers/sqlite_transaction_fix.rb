module SqliteTransactionFix
  MAX_SLEEP = 30
  
  def begin_db_transaction(write_timeout = 5000) #:nodoc:
    @sleep ||= 0.001
    @sleep = 0.001 if @sleep >= MAX_SLEEP
    
    if write_timeout.nil?
      @connection.transaction(:deferred) # Deferred is the default.
    else
      deadline = Time.new + (write_timeout.to_f / 1000)
      success = false
      tries = 0
      while (!success and Time.new() < deadline) do
        tries = tries + 1
        begin
          @connection.transaction(:immediate)
          success = true
        rescue SQLite3::BusyException
          sleep (@sleep = @sleep * 2)
        end
      end
      raise SQLite3::BusyException("Retries: #{tries}, sleep: #{@sleep}") unless success
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class SQLite3Adapter < AbstractAdapter
      prepend SqliteTransactionFix
    end
  end
end
