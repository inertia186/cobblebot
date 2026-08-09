require 'test_helper'
require 'stringio'
require 'minitest/mock'

class MinecraftWatchdogTest < ActiveSupport::TestCase
  include WebStubs

  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_perform_runs_one_policy_and_maintenance_pass_without_sleep_or_queue_inspection
    calls = Hash.new(0)

    MinecraftWorkerQueuePolicy.stub(:call, -> { calls[:policy] += 1 }) do
      MinecraftWatchdog.stub(:check_resource_pack, -> { calls[:resource_pack] += 1 }) do
        MinecraftWatchdog.stub(:prettify_callbacks, -> { calls[:callbacks] += 1 }) do
          MinecraftWatchdog.stub(:update_ip_cc, -> { calls[:ip_cc] += 1 }) do
            MinecraftWatchdog.stub(:update_player_stats, -> { calls[:stats] += 1 }) do
              MinecraftWatchdog.stub(:sleep, ->(*) { flunk 'watchdog must not sleep' }) do
                Resque.stub(:size, ->(*) { flunk 'watchdog must not inspect queue depth' }) do
                  MinecraftWatchdog.perform(debug: true)
                end
              end
            end
          end
        end
      end
    end

    assert_equal({
      policy: 1,
      resource_pack: 1,
      callbacks: 1,
      ip_cc: 1,
      stats: 1
    }, calls)
  end

  def test_perform_preserves_deferred_operation_handling
    options = {'operation' => 'update_player_last_ip'}
    received = nil

    MinecraftWatchdog.stub(:deferred_operation, ->(value) { received = value }) do
      MinecraftWorkerQueuePolicy.stub(:call, -> { raise Errno::ENOENT, 'setup incomplete' }) do
        MinecraftWatchdog.perform(options)
      end
    end

    assert_same options, received
  end

  def test_perform_logs_incomplete_setup_and_returns_without_sleeping
    output = StringIO.new
    logger = Logger.new(output)

    Rails.stub(:logger, logger) do
      MinecraftWorkerQueuePolicy.stub(:call, -> { raise Errno::ENOENT, 'setup incomplete' }) do
        MinecraftWatchdog.stub(:sleep, ->(*) { flunk 'watchdog must not sleep' }) do
          assert_nil MinecraftWatchdog.perform
        end
      end
    end

    assert_includes output.string, 'Need to finish setup:'
    assert_includes output.string, 'setup incomplete'
  end

  def test_prettification_failure_is_logged_without_aborting_maintenance
    failed_callback = Struct.new(:id, :pretty_pattern, :pretty_command).new(1, nil, 'already pretty')
    later_callback = Struct.new(:id, :pretty_pattern, :pretty_command).new(2, nil, 'already pretty')
    later_calls = []
    failed_callback.define_singleton_method(:prettify) { |*| raise Net::ReadTimeout }
    later_callback.define_singleton_method(:prettify) { |key| later_calls << key }
    callbacks = Object.new
    callbacks.define_singleton_method(:find_each) do |&block|
      [failed_callback, later_callback].each(&block)
    end
    output = StringIO.new

    ServerCallback.stub(:needs_prettification, callbacks) do
      Rails.stub(:logger, Logger.new(output)) do
        MinecraftWatchdog.prettify_callbacks
      end
    end

    assert_includes output.string, 'Unable to prettify ServerCallback'
    assert_includes output.string, 'Net::ReadTimeout'
    assert_equal [:pattern], later_calls
  end

  def test_unknown_operation_that_contains_a_deferred_name_is_not_dispatched_or_retried
    output = StringIO.new
    options = {'operation' => 'not_update_player_quotes'}

    Rails.stub(:logger, Logger.new(output)) do
      MinecraftWatchdog.stub(:update_player_quotes, ->(*) { flunk 'unknown operation must not be dispatched' }) do
        MinecraftWatchdog.stub(:_retry, ->(*) { flunk 'unknown operation must not be retried' }) do
          MinecraftWatchdog.send(:deferred_operation, options)
        end
      end
    end

    assert_includes output.string, 'Unknown operation: not_update_player_quotes'
  end

  def test_failed_resource_pack_download_preserves_cache_and_retry_timestamp
    Preference.latest_resource_pack_hash = 'cached-hash'
    Preference.latest_resource_pack_timestamp = 2.days.ago.to_i
    agent = Object.new
    agent.define_singleton_method(:get) { |*| raise Net::ReadTimeout }

    CobbleBotAgent.stub(:new, agent) do
      MinecraftWatchdog.check_resource_pack
    end

    assert_equal 'cached-hash', Preference.latest_resource_pack_hash
    assert_operator Preference.latest_resource_pack_timestamp.to_i, :<=, 24.hours.ago.to_i
  end

  def test_successful_resource_pack_download_updates_hash_and_timestamp
    Preference.latest_resource_pack_hash = 'cached-hash'
    Preference.latest_resource_pack_timestamp = 2.days.ago.to_i
    body = 'new resource pack'
    page = Struct.new(:body).new(body)
    agent = Object.new
    agent.define_singleton_method(:get) { |*| true }
    agent.define_singleton_method(:page) { page }

    CobbleBotAgent.stub(:new, agent) do
      MinecraftWatchdog.check_resource_pack
    end

    assert_equal Digest::MD5.hexdigest(body), Preference.latest_resource_pack_hash
    assert_operator Preference.latest_resource_pack_timestamp.to_i, :>, 1.minute.ago.to_i
  end

  def test_player_stat_failure_is_wrapped_without_masking_the_original_error
    players = Object.new
    original = RuntimeError.new('stats unavailable')
    players.define_singleton_method(:find_each) { raise original }
    output = StringIO.new

    Player.stub(:shall_update_stats, players) do
      Rails.stub(:logger, Logger.new(output)) do
        assert_equal [], MinecraftWatchdog.update_player_stats
      end
    end

    assert_includes output.string, 'Unable to update player stats.'
    assert_includes output.string, 'stats unavailable'
    refute_includes output.string, 'NameError'
  end
end
