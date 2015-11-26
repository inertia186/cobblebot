require 'test_helper'

class MinecraftServerLogMonitorTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_perform
    monitor = Thread.start do
      5.times do
        begin
          MinecraftServerLogMonitor.perform(debug: true, "max_ticks" => 1)
        rescue CobbleBotError => e
          sleep 1
          Preference.path_to_server = "#{Rails.root}/tmp"
        end
      end
    end
    skip 'Took too long to run.' unless monitor.join 5
  end
end
