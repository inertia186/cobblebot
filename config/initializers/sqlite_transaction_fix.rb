module SqliteTransactionFix
  def begin_db_transaction
    log('begin immediate transaction', nil) do
      @connection.transaction(:immediate)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class SQLiteAdapter < AbstractAdapter
      prepend SqliteTransactionFix
    end
  end
end
