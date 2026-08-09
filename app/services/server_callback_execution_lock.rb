require 'fileutils'
require 'digest'

class ServerCallbackExecutionLock
  POSTGRESQL_NAMESPACE = 1_129_269_826

  def self.synchronize(callback, adapter_name: ActiveRecord::Base.connection.adapter_name,
                       connection_pool: ActiveRecord::Base.connection_pool,
                       lock_root: Rails.root.join('tmp/locks'), &block)
    new(
      callback: callback,
      adapter_name: adapter_name,
      connection_pool: connection_pool,
      lock_root: lock_root
    ).synchronize(&block)
  end

  def initialize(callback:, adapter_name:, connection_pool:, lock_root:)
    @callback = callback
    @adapter_name = adapter_name.to_s.downcase
    @connection_pool = connection_pool
    @lock_root = Pathname.new(lock_root)
  end

  def synchronize(&block)
    case adapter_name
    when 'postgresql'
      with_postgresql_lock(&block)
    when 'sqlite', 'sqlite3'
      with_file_lock(&block)
    else
      raise NotImplementedError,
        "Unsupported callback-lock adapter '#{adapter_name}'"
    end
  end

private
  attr_reader :adapter_name, :callback, :connection_pool, :lock_root

  def with_postgresql_lock
    connection_pool.with_connection do |connection|
      lock_key = postgresql_lock_key
      connection.raw_connection.exec_params(
        'SELECT pg_advisory_lock($1::bigint)',
        [lock_key]
      )
      begin
        yield
      ensure
        connection.raw_connection.exec_params(
          'SELECT pg_advisory_unlock($1::bigint)',
          [lock_key]
        )
      end
    end
  end

  def postgresql_lock_key
    callback_id = Integer(callback.id)
    Digest::SHA256.digest("#{POSTGRESQL_NAMESPACE}:#{callback_id}").unpack1('q>')
  end

  def with_file_lock
    FileUtils.mkdir_p(lock_root)
    path = lock_root.join("server_callback_#{Integer(callback.id)}.lock")
    File.open(path, File::RDWR | File::CREAT, 0o600) do |file|
      file.flock(File::LOCK_EX)
      begin
        yield
      ensure
        file.flock(File::LOCK_UN)
      end
    end
  end
end
