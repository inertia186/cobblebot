require 'test_helper'

class PlayersControllerTest < ActionController::TestCase
  def setup
    Preference.path_to_server = "#{Rails.root}/tmp"
  end
  
  def test_routings
    assert_routing({ method: 'get', path: '/' }, controller: 'players', action: 'index')
  end

  def test_index
    Server.mock_mode(up: true, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        get :index
        players = assigns :players
        assert players, 'expect players'

        assert_template 'layouts/application'
        assert_response :success
      end
    end
  end

  def test_index_down
    get :index
    players = assigns :players
    refute players, 'did not expect players'

    assert_template 'layouts/application'
    assert_response 500 # because the minecraft server isn't responding to the socket
  end

  def test_index_js_server_down
    get :index, format: :js, after: Time.now.to_i.to_s

    assert_response 204
  end

  def test_index_js_after_undefined
    get :index, format: :js, after: 'undefined'

    assert_response 204
  end

  def test_index_js_log_old
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do

        get :index, format: :js, after: Time.now.to_i.to_s

        assert_response 204
      end
    end
  end

  def test_index_js_log_current
    after = 10.minutes.ago
    
    player = Player.limit(1).last
    player.update_attributes(last_logout_at: after, last_chat: 'bye', last_chat_at: after)
    
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        xhr :get, :index, format: :js, after: after.to_i.to_s
        assert assigns(:new_chat).empty?, 'expect empty new chat'
    
        assert_response 200
      end
    end
  end
  
  def test_index_js_player_idle
    after = 10.minutes.ago
    
    Player.find_each do |player|
      player.update_attributes(last_login_at: after, last_chat_at: after, last_logout_at: after, updated_at: after)
    end
    
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        xhr :get, :index, format: :js, after: after.to_i.to_s
    
        assert_response 204
      end
    end
  end

  def test_index_js
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        get :index, format: :js, after: Time.now.to_i.to_s
        players = assigns :players
        assert players, 'expect players'
        new_chat = assigns :new_chat
        assert_nil new_chat, 'expect nil new chat'

        assert_response 204
      end
    end
  end
end
