require 'test_helper'

class Admin::PlayersControllerTest < ActionController::TestCase
  def setup
    preferences(:path_to_server).update_attribute(:value, "#{Rails.root}/tmp")
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/players' }, controller: 'admin/players', action: 'index')
    assert_routing({ method: 'get', path: 'admin/players.json' }, controller: 'admin/players', action: 'index', format: 'json')
    assert_routing({ method: 'get', path: 'admin/players/42' }, controller: 'admin/players', action: 'show', id: '42')
    assert_routing({ method: 'delete', path: 'admin/players/42' }, controller: 'admin/players', action: 'destroy', id: '42')
    assert_routing({ method: 'patch', path: 'admin/players/42/toggle_may_autolink' }, controller: 'admin/players', action: 'toggle_may_autolink', id: '42')
    assert_routing({ method: 'patch', path: 'admin/players/42/toggle_may_autolink.js' }, controller: 'admin/players', action: 'toggle_may_autolink', id: '42', format: 'js')
  end

  def test_index
    get :index
    players = assigns :players
    refute_equal players.count, 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_query
    get :index, params: { query: 'inertia' }
    players = assigns :players
    refute_equal players.count, 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_json
    get :index, params: { format: :json, select: 'id,nick,last_nick' }
    players = assigns :players
    refute_empty players.to_a, 'did not expect zero count'
    assert_equal %w[id last_nick nick], players.first.attributes.keys.sort

    assert_template nil
    assert_response :success
  end

  def test_index_rejects_unapproved_select_expressions
    get :index, params: {
      format: :json,
      select: 'id,(SELECT COUNT(*) FROM messages) AS messages_count'
    }

    assert_response :bad_request
  end

  def test_show
    get :show, params: { id: Player.first }
    refute_nil assigns :player

    assert_template :show
    assert_response :success
  end

  def test_toggle_may_autolink
    assert_difference -> { Player.may_autolink.count }, -1, 'expect different count' do
      patch :toggle_may_autolink, params: { format: :js, id: Player.first }
    end

    assert_template 'admin/players/_player'
    assert_template 'admin/players/show'
    assert_response :success
  end

  def test_destroy
    assert_difference -> { Player.count }, -1, 'expect different count' do
      delete :destroy, params: { id: Player.first }
    end

    assert_template nil
    assert_redirected_to admin_players_url
  end
end
