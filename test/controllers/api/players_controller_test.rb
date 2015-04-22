require 'test_helper'

class Api::V1::PlayersControllerTest < ActionController::TestCase
  def test_routings
    assert_routing 'api/players', controller: 'api/v1/players', action: 'index', format: 'json'
    assert_routing 'api/players/42', controller: 'api/v1/players', action: 'show', id: '42', format: 'json'
  end

  def index
    get :index, only_registered: true
    assert_response 200

    assert_template :index
    assert_template partial: "api/v1/players/_minimal_player"
  end

  def index_any_nick
    player = Player.find_by_nick 'inertia186'
    get :index, only_registered: true, any_nick: player.nick
    assert_response 200

    %w(uuid nick registered_at).each do |attr|
      assert_equal player.send(attr), response_json[0][attr]
    end

    assert_template :index
    assert_template partial: "api/v1/players/_minimal_player"
  end

  def test_show
    player = Player.find_by_nick 'inertia186'
    # TODO use request_token
    #request_token @access_token.token
    get :show, id: player.id, format: :json
    assert_response 200
    %w(uuid nick registered_at).each do |attr|
      assert_equal player.send(attr), response_json[attr]
    end

    assert_template :show
    assert_template partial: "api/v1/players/_minimal_player"
  end
end
