require 'test_helper'

class MinecraftWatchdogTest < ActiveSupport::TestCase
  def setup
    seed
    Preference.path_to_server = "#{Rails.root}/tmp"
    
    stub_request(:get, ServerProperties.resource_pack).
      to_return(status: 200)
    stub_request(:post, "http://pygments.appspot.com/").
      to_return(status: 200)
  end
  
  def test_perform
    MinecraftWatchdog.perform(debug: true)
    
    assert Resque.queues.include?('minecraft_watchdog'), 'expect queue'
    assert Resque.size('minecraft_watchdog') > 0, 'expect non-zero queue'
  end
end
