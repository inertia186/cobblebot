require 'test_helper'
require 'rake'
require 'minitest/mock'

class CobblebotWorkersTaskTest < ActiveSupport::TestCase
  def setup
    ApplicationTaskTestSupport.load
    task.reenable
  end

  def test_reports_an_enqueued_watchdog
    output = MinecraftWatchdogBootstrap.stub(:call, :enqueued) do
      capture_io { task.invoke }.first
    end

    assert_equal "Enqueued Minecraft watchdog.\n", output
  end

  def test_reports_an_existing_watchdog
    output = MinecraftWatchdogBootstrap.stub(:call, :already_present) do
      capture_io { task.invoke }.first
    end

    assert_equal "Minecraft watchdog is already queued or running.\n", output
  end

  def test_propagates_bootstrap_failures
    failure = proc do
      raise CobbleBotError.new(message: MinecraftWatchdogBootstrap::REDIS_UNAVAILABLE_MESSAGE)
    end

    error = MinecraftWatchdogBootstrap.stub(:call, failure) do
      assert_raises(CobbleBotError) { task.invoke }
    end

    assert_equal MinecraftWatchdogBootstrap::REDIS_UNAVAILABLE_MESSAGE, error.message
  end

private
  def task
    Rake::Task['cobblebot:workers:bootstrap']
  end
end
