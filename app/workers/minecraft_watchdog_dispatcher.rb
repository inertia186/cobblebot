class MinecraftWatchdogDispatcher
  QUEUE = MinecraftWatchdog::QUEUE
  @queue = QUEUE

  def self.perform
    MinecraftWatchdogBootstrap.call
  end
end
