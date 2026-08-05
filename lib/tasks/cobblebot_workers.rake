namespace :cobblebot do
  namespace :workers do
    desc 'Enqueue the Minecraft watchdog unless it is already queued or running'
    task bootstrap: :environment do
      case MinecraftWatchdogBootstrap.call
      when :enqueued
        puts 'Enqueued Minecraft watchdog.'
      when :already_present
        puts 'Minecraft watchdog is already queued or running.'
      else
        raise CobbleBotError.new(message: 'Minecraft watchdog bootstrap returned an unknown result.')
      end
    end
  end
end
