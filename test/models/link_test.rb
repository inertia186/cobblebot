require 'test_helper'

class LinkTest < ActiveSupport::TestCase
  def setup
    seed
  end
  
  def test_title
    cobblebot = Link.where(url: 'http://github.com/inertia186/cobblebot').first
    cobblebot.update_attribute(:expires_at, 2.days.from_now)
    
    assert_equal cobblebot.title, 'inertia186/cobblebot - GitHub', 'expect title not to expire'
  end
end