require 'test_helper'
require 'tempfile'

class SqliteTransactionModeTest < Minitest::Test
  class PrimaryRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  class SecondaryRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  class TimeoutRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  class PrimaryWidget < PrimaryRecord
    self.table_name = 'widgets'
  end

  class SecondaryWidget < SecondaryRecord
    self.table_name = 'widgets'
  end

  class TimeoutWidget < TimeoutRecord
    self.table_name = 'widgets'
  end

  def setup
    database = Tempfile.new(['cobblebot-transactions', '.sqlite3'])
    @database_path = database.path
    database.close

    PrimaryRecord.establish_connection(connection_config(timeout: 1_000))
    SecondaryRecord.establish_connection(connection_config(timeout: 1_000))
    TimeoutRecord.establish_connection(connection_config(timeout: 50))

    PrimaryRecord.connection.create_table(:widgets) do |table|
      table.string :name, null: false
    end

    [PrimaryWidget, SecondaryWidget, TimeoutWidget].each(&:reset_column_information)
  end

  def teardown
    [TimeoutRecord, SecondaryRecord, PrimaryRecord].each do |record|
      record.remove_connection
    rescue ActiveRecord::ConnectionNotEstablished
      nil
    end

    File.delete(database_path) if database_path && File.exist?(database_path)
  end

  def test_application_configures_only_sqlite_environments_for_immediate_transactions
    development = database_config_for('development')
    production = database_config_for('production')
    test = database_config_for('test')

    assert_equal 'sqlite3', development[:adapter]
    assert_equal 'immediate', development[:default_transaction_mode]
    assert_equal 15_000, development[:timeout]

    assert_equal 'sqlite3', production[:adapter]
    assert_equal 'immediate', production[:default_transaction_mode]
    assert_equal 15_000, production[:timeout]

    assert_equal 'postgresql', test[:adapter]
    refute test.key?(:default_transaction_mode)
  end

  def test_native_rails_transaction_acquires_an_immediate_write_reservation
    adapter = PrimaryRecord.connection
    contender = SQLite3::Database.new(database_path)
    contender.busy_timeout(0)
    transaction_started = false

    assert_equal ActiveRecord::ConnectionAdapters::SQLite3::DatabaseStatements,
      adapter.method(:begin_db_transaction).owner

    adapter.begin_db_transaction
    transaction_started = true

    assert_raises(SQLite3::BusyException) do
      contender.transaction(:immediate)
    end
  ensure
    adapter.exec_rollback_db_transaction if transaction_started
    contender.close if contender
  end

  def test_commit_rollback_and_nested_savepoints
    PrimaryRecord.transaction do
      PrimaryWidget.create!(name: 'committed')
    end

    PrimaryRecord.transaction do
      PrimaryWidget.create!(name: 'rolled back')
      raise ActiveRecord::Rollback
    end

    PrimaryRecord.transaction do
      PrimaryWidget.create!(name: 'outer before')

      PrimaryRecord.transaction(requires_new: true) do
        PrimaryWidget.create!(name: 'inner rolled back')
        raise ActiveRecord::Rollback
      end

      PrimaryWidget.create!(name: 'outer after')
    end

    assert_equal ['committed', 'outer before', 'outer after'], PrimaryWidget.order(:id).pluck(:name)
  end

  def test_concurrent_process_writer_waits_for_the_first_transaction
    ready_reader, ready_writer = IO.pipe
    start_reader, start_writer = IO.pipe
    result_reader, result_writer = IO.pipe

    writer_pid = Process.fork do
      ready_reader.close
      start_writer.close
      result_reader.close

      [TimeoutRecord, SecondaryRecord, PrimaryRecord].each do |record|
        record.connection_pool.disconnect!
      end

      SecondaryRecord.establish_connection(connection_config(timeout: 1_000))
      SecondaryWidget.reset_column_information
      ready_writer.write('1')
      ready_writer.close
      start_reader.read(1)

      SecondaryRecord.transaction do
        SecondaryWidget.create!(name: 'secondary')
      end

      result_writer.write('committed')
    rescue => error
      result_writer.write("#{error.class}: #{error.message}")
    ensure
      SecondaryRecord.connection_pool.disconnect! rescue nil
      start_reader.close rescue nil
      result_writer.close rescue nil
      exit! 0
    end

    ready_writer.close
    start_reader.close
    result_writer.close

    assert IO.select([ready_reader], nil, nil, 2), 'concurrent writer did not initialize'
    ready_reader.read(1)

    PrimaryRecord.transaction do
      PrimaryWidget.create!(name: 'primary')
      start_writer.write('1')
      start_writer.close
      sleep 0.1
    end

    assert IO.select([result_reader], nil, nil, 2), 'concurrent writer did not finish'
    assert_equal 'committed', result_reader.read
    Process.wait(writer_pid)
    writer_pid = nil
    assert_equal ['primary', 'secondary'], PrimaryWidget.order(:id).pluck(:name)
  ensure
    [ready_reader, ready_writer, start_reader, start_writer, result_reader, result_writer].compact.each do |io|
      io.close unless io.closed?
    rescue IOError
      nil
    end

    if writer_pid
      Process.kill('TERM', writer_pid) rescue nil
      Process.wait(writer_pid) rescue nil
    end
  end

  def test_busy_timeout_raises_the_native_active_record_error
    error = nil

    PrimaryRecord.transaction do
      PrimaryWidget.create!(name: 'primary')

      error = assert_raises(ActiveRecord::StatementInvalid) do
        TimeoutRecord.transaction do
          TimeoutWidget.create!(name: 'timed out')
        end
      end
    end

    assert_kind_of SQLite3::BusyException, error.cause
    refute_instance_of CobbleBotError, error
  ensure
    TimeoutRecord.connection_pool.release_connection
  end

private
  attr_reader :database_path

  def connection_config(timeout:)
    {
      adapter: 'sqlite3',
      database: database_path,
      timeout: timeout,
      default_transaction_mode: :immediate
    }
  end

  def database_config_for(environment)
    YAML.load_file(Rails.root.join('config/database.yml'), aliases: true).
      fetch(environment).
      symbolize_keys
  end
end
