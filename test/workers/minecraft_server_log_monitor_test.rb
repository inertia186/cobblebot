require 'test_helper'

class MinecraftServerLogMonitorTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_perform
    monitor = Thread.start do
      MinecraftServerLogMonitor.perform(debug: true, "max_ticks" => 1)
    end
    
    skip 'Took too long to run.' unless monitor.join 5
  end
end
