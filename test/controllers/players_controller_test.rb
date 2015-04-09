require 'test_helper'

class PlayersControllerTest < ActionController::TestCase
  def test_routings
    assert_routing({ method: 'get', path: '/' }, controller: 'players', action: 'index')
  end

  def test_index
    def Server.up?
      true
    end
    
    def Server.players(selector = nil)
      [Player.first]
    end
    
    def ServerQuery.full_query
      { numplayers: '1', maxplayers: '20' }
    end
    
    get :index
    players = assigns :players
    assert players, 'expect players'
    
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_index_down
    def Server.up?
      false
    end

    get :index
    players = assigns :players
    refute players, 'did not expect players'
    
    assert_template 'layouts/application'
    assert_response 500 # because the minecraft server isn't responding to the socket
  end
end
