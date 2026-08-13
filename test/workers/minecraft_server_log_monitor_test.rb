require 'test_helper'
require 'minitest/mock'

class MinecraftServerLogMonitorTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_perform_delegates_existing_options_to_the_tailer
    actual = nil
    preloaded = false
    tailer = lambda do |**options|
      actual = options
      :completed
    end

    ServerCallback.stub(:preload_sti_types!, -> { preloaded = true }) do
      Resque.stub(:size, ->(*) { flunk 'log monitor must not inspect Redis queue depth' }) do
        Server.stub(:latest_log_entry_at, -> { flunk 'log monitor must not query Minecraft status' }) do
          MinecraftServerLogTailer.stub(:call, tailer) do
            result = MinecraftServerLogMonitor.perform(
              "server_log" => '/minecraft/logs/latest.log',
              "log_length" => 25,
              "monitor_tick" => 0.1,
              "tick_multiplier" => 3,
              "max_ticks" => 7
            )

            assert_equal :completed, result
          end
        end
      end
    end

    assert preloaded, 'expected callback STI types to load before tailing'
    assert_equal({
      server_log: '/minecraft/logs/latest.log',
      log_length: 25,
      monitor_tick: 0.1,
      tick_multiplier: 3,
      max_ticks: 7
    }, actual)
  end

  def test_perform_uses_existing_defaults
    actual = nil

    MinecraftServerLogTailer.stub(:call, ->(**options) { actual = options }) do
      MinecraftServerLogMonitor.perform
    end

    assert_equal "#{Rails.root}/tmp/logs/latest.log", actual.fetch(:server_log)
    assert_equal MinecraftServerLogMonitor::DEFAULT_LOG_LENGTH, actual.fetch(:log_length)
    assert_equal MinecraftServerLogMonitor::DEFAULT_MONITOR_TICK, actual.fetch(:monitor_tick)
    assert_equal MinecraftServerLogMonitor::DEFAULT_TICK_MULTIPLIER, actual.fetch(:tick_multiplier)
    assert_equal MinecraftServerLogMonitor::DEFAULT_MAX_TICKS, actual.fetch(:max_ticks)
  end
end
