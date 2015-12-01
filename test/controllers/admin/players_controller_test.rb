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
    get :index, query: 'inertia'
    players = assigns :players
    refute_equal players.count, 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_json
    get :index, format: :json, select: '*'
    players = assigns :players
    refute_equal players.count, 0, 'did not expect zero count'

    assert_template nil
    assert_response :success
  end

  def test_show
    get :show, id: Player.first
    refute_nil assigns :player

    assert_template :show
    assert_response :success
  end

  def test_toggle_may_autolink
    assert_difference -> { Player.may_autolink.count }, -1, 'expect different count' do
      patch :toggle_may_autolink, format: :js, id: Player.first
    end

    assert_template 'admin/players/_player'
    assert_template 'admin/players/show'
    assert_response :success
  end

  def test_destroy
    assert_difference -> { Player.count }, -1, 'expect different count' do
      delete :destroy, id: Player.first
    end

    assert_template nil
    assert_redirected_to admin_players_url
  end
end
