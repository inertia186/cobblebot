require 'test_helper'

class MinecraftWatchdogDispatcherTest < ActiveSupport::TestCase
  def test_dispatches_through_the_atomic_bootstrap
    MinecraftWatchdogBootstrap.stub(:call, :enqueued) do
      assert_equal :enqueued, MinecraftWatchdogDispatcher.perform
    end
  end

  def test_uses_the_watchdog_queue
    assert_equal MinecraftWatchdog::QUEUE, MinecraftWatchdogDispatcher::QUEUE
  end
end
