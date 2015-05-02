require 'test_helper'

class MinecraftServerLogMonitorTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_perform
    MinecraftServerLogMonitor.perform(debug: true, "max_ticks" => 1)
  end
end