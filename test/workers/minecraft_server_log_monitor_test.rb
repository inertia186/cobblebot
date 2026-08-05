require 'test_helper'
require 'minitest/mock'

class MinecraftServerLogMonitorTest < ActiveSupport::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_perform_is_bounded_only_by_max_ticks
    completed = false

    Resque.stub(:size, ->(*) { flunk 'log monitor must not inspect Redis queue depth' }) do
      MinecraftServerLogMonitor.perform(debug: true, "max_ticks" => 1)
      completed = true
    end

    assert completed
  end
end
