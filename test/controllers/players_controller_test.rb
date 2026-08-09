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
        assert_select 'table > tbody', count: 1
        assert_select 'table tr tr', count: 0
        assert_select 'table > tbody > tr > th[colspan="6"]',
          text: /Logged in Today/
      end
    end
  end

  def test_index_down
    Server.mock_mode(up: false, player_nicks: []) do
      get :index
    end

    refute assigns(:players), 'did not expect players'
    assert_template 'layouts/application'
    assert_response :internal_server_error
  end

  def test_index_js_server_down
    get :index, params: { format: :js, after: Time.now.to_i.to_s }

    assert_response 204
  end

  def test_index_js_after_undefined
    get :index, params: { format: :js, after: 'undefined' }

    assert_response 204
  end

  def test_index_js_rejects_invalid_polling_cursors
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: []) do
      ['not-a-timestamp', '-1', '9' * 1000].each do |cursor|
        get :index, params: {format: :js, after: cursor}
        assert_response 204
      end
    end
  end

  def test_index_js_log_old
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do

        get :index, params: { format: :js, after: Time.now.to_i.to_s }

        assert_response 204
      end
    end
  end

  def test_index_js_log_current
    after = 10.minutes.ago
    
    player = Player.limit(1).last
    player.update!(last_logout_at: after, last_chat: 'bye', last_chat_at: after)
    
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        get :index, params: { format: :js, after: after.to_i.to_s }, xhr: true
        assert assigns(:new_chat).empty?, 'expect empty new chat'
    
        assert_response 200
      end
    end
  end
  
  def test_index_js_player_idle
    after = 10.minutes.ago
    
    Player.find_each do |player|
      player.update!(last_login_at: after, last_chat_at: after, last_logout_at: after, updated_at: after)
    end
    
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        get :index, params: { format: :js, after: after.to_i.to_s }, xhr: true
    
        assert_response 204
      end
    end
  end

  def test_index_js_after_with_last_chat
    after = 10.minutes.ago
    player = Player.last
    player.update!(last_chat: 'Hello.', last_chat_at: Time.now)

    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: [player.nick]) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        get :index, params: { format: :js, after: after.to_i.to_s }, xhr: true

        assert_response 200
      end
    end
  end

  def test_index_js_safely_autolinks_hostile_chat
    after = 10.minutes.ago
    player = Player.last
    player.update!(
      last_chat: 'Visit http://example.test/path"><img src=x onerror=alert(1)>',
      last_chat_at: Time.current
    )

    Server.mock_mode(
      up: true, latest_log_entry_at: Time.current, player_nicks: [player.nick]
    ) do
      ServerQuery.mock_mode(full_query: {numplayers: '1', maxplayers: '20'}) do
        get :index, params: {format: :js, after: after.to_i.to_s}, xhr: true

        assert_response :success
        assert_includes response.body, 'http://example.test/path'
        linked_text = response.body.lines.find do |line|
          line.strip.start_with?("text = '")
        end
        assert_includes linked_text, '<img src=x onerror=alert(1)>'
        refute_includes response.body, '<a target='
      end
    end
  end

  def test_index_js
    Server.mock_mode(up: true, latest_log_entry_at: Time.now, player_nicks: Player.limit(1).pluck(:nick)) do
      ServerQuery.mock_mode(full_query: {numplayers: "1", maxplayers: "20"}) do
        get :index, params: { format: :js, after: Time.now.to_i.to_s }
        players = assigns :players
        assert players, 'expect players'
        new_chat = assigns :new_chat
        assert_nil new_chat, 'expect nil new chat'

        assert_response 204
      end
    end
  end
end
