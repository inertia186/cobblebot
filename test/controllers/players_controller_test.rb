require 'test_helper'

class PlayersControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: '/' }, controller: 'players', action: 'index')
  end
  
  def test_index
    get :index
    players = assigns :players
    refute players, 'did not expect players'
    
    assert_template 'layouts/application'
    assert_response 500 # because the minecraft server isn't responding to the socket
  end
end
