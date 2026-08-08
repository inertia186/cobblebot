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
    callback = ServerCallback.first
    callback.update_columns(pretty_pattern: nil, pretty_command: 'already pretty')
    callbacks = Object.new
    callbacks.define_singleton_method(:find_each) { |&block| block.call(callback) }

    callback.stub(:prettify, ->(*) { raise Net::ReadTimeout }) do
      output = StringIO.new

      ServerCallback.stub(:needs_prettification, callbacks) do
        Rails.stub(:logger, Logger.new(output)) do
          MinecraftWatchdog.prettify_callbacks
        end
      end

      assert_includes output.string, 'Unable to prettify ServerCallback'
      assert_includes output.string, 'Net::ReadTimeout'
    end
  end
end
