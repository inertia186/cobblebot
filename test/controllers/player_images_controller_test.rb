require 'test_helper'

class PlayerImagesControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: '/player_images/inertia186/16.png' }, controller: 'player_images', action: 'show', id: 'inertia186', size: '16', format: 'png')
  end

  def test_show
  end
end