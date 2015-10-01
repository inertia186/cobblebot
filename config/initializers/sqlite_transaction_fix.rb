module SqliteTransactionFix
  def begin_db_transaction(write_timeout = 5000) #:nodoc:
    if write_timeout.nil?
      @connection.transaction(:deferred) # Deferred is the default.
    else
      deadline = Time.new + (write_timeout.to_f / 1000)
      success = false
      while (!success and Time.new() < deadline) do
        begin
          @connection.transaction(:immediate)
          success = true
        rescue SQLite3::BusyException
          sleep 0.001
        end
      end
      raise SQLite3::BusyException unless success
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
