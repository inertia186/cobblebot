require 'test_helper'

class IpTest < ActiveSupport::TestCase
  def setup
  end
  
  def test_origin
    ip = Ip.create(address: '127.0.0.1', player: Player.last)
    
    refute_nil ip.origin, 'expect origin'
  end
end