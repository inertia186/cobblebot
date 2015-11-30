require 'test_helper'

class MinecraftWatchdogTest < ActiveSupport::TestCase
  include WebStubs

  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end

  def test_perform
    stub_resource_pack do
      stub_pygments do
        MinecraftWatchdog.perform(debug: true)
      end
    end
  end
end
