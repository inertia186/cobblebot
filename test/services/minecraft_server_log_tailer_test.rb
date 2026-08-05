require 'test_helper'
require 'stringio'

class MinecraftServerLogTailerTest < ActiveSupport::TestCase
  class FakeLog
    attr_accessor :interval, :max_interval, :return_if_eof
    attr_reader :backward_calls, :extended_with, :tail_calls

    def initialize(batches = [])
      @batches = batches
      @backward_calls = []
      @extended_with = []
      @tail_calls = []
    end

    def extend(extension)
      @extended_with << extension
      self
    end

    def backward(lines)
      @backward_calls << lines
      self
    end

    def tail(lines)
      @tail_calls << lines
      Array(@batches.shift).each { |line| yield line }
    end
  end

  class FakeFileOpener
    attr_reader :paths

    def initialize(log: nil, error: nil)
      @log = log
      @error = error
      @paths = []
    end

    def open(path)
      @paths << path
      raise @error if @error

      yield @log
    end
  end

  class FakeHandler
    attr_reader :lines

    def initialize
      @lines = []
    end

    def handle(line)
      @lines << line
    end
  end

  class FakeSleeper
    attr_reader :intervals

    def initialize
      @intervals = []
    end

    def sleep(interval)
      @intervals << interval
    end
  end

  def setup
    @log_output = StringIO.new
    @logger = Logger.new(@log_output)
    @handler = FakeHandler.new
    @sleeper = FakeSleeper.new
  end

  def test_configures_one_tail_and_polls_exactly_max_ticks
    log = FakeLog.new([["first\n", "first\n"], ["second\n"], []])
    opener = FakeFileOpener.new(log: log)

    assert_equal :completed, call_tailer(
      file_opener: opener,
      log: log,
      max_ticks: 3,
      log_length: 100
    )

    assert_equal ['/minecraft/logs/latest.log'], opener.paths
    assert_equal [File::Tail], log.extended_with
    assert_equal [0], log.backward_calls
    assert_equal [100, 100, 100], log.tail_calls
    assert_equal 0.25, log.interval
    assert_equal 0.5, log.max_interval
    assert log.return_if_eof
    assert_equal ["first\n", "second\n"], @handler.lines
    assert_equal [0.25, 0.25, 0.25], @sleeper.intervals
  end

  def test_duplicate_cache_resets_after_log_length_lines
    log = FakeLog.new([["same\n", "same\n"], ["same\n"]])

    call_tailer(log: log, max_ticks: 2, log_length: 2)

    assert_equal ["same\n", "same\n"], @handler.lines
  end

  def test_logs_a_slow_handler
    log = FakeLog.new([["slow\n"]])
    times = [10.0, 10.3]

    call_tailer(log: log, max_ticks: 1, clock: -> { times.shift })

    assert_includes @log_output.string,
      'Logging interval elapsed time greater than monitor tick: 0.3'
  end

  def test_missing_initial_log_returns_without_sleeping
    opener = FakeFileOpener.new(error: Errno::ENOENT.new('/missing/latest.log'))

    assert_equal :missing, call_tailer(file_opener: opener)
    assert_empty @sleeper.intervals
    assert_includes @log_output.string, 'Need to finish setup:'
  end

  def test_resque_termination_is_reported
    log = FakeLog.new
    log.define_singleton_method(:tail) do |_lines|
      raise Resque::TermException.new('TERM')
    end

    assert_equal :terminated, call_tailer(log: log)
    assert_includes @log_output.string, 'Detected ^C'
  end

private
  def call_tailer(log: FakeLog.new, file_opener: nil, max_ticks: 1,
                  log_length: 100, clock: -> { 0.0 })
    MinecraftServerLogTailer.call(
      server_log: '/minecraft/logs/latest.log',
      log_length: log_length,
      monitor_tick: 0.25,
      tick_multiplier: 2,
      max_ticks: max_ticks,
      file_opener: file_opener || FakeFileOpener.new(log: log),
      handler: @handler,
      logger: @logger,
      sleeper: @sleeper,
      clock: clock
    )
  end
end
