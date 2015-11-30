require 'test_helper'

class Admin::LinksControllerTest < ActionController::TestCase
  include WebStubs

  def setup
    session[:admin_signed_in] = true
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/links' }, controller: 'admin/links', action: 'index')
  end

  def test_index
    get :index
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_sort_by_link_linked_by
    stub_mit do
      stub_github do
        get :index, sort_field: 'link_linked_by'
      end
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_feed
    basic = ActionController::HttpAuthentication::Basic
    credentials = basic.encode_credentials('admin', Preference.web_admin_password)
    request.headers['Authorization'] = credentials

    stub_mit do
      stub_github do
        get :index, format: :atom
      end
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index
    stub_mit do
      get :index, query: 'mit'
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_for_players
    player = Player.first
    assert_difference -> { player.links.count }, 1, 'expect different count' do
      Link.first.update_attribute(:actor, player)
    end

    stub_mit do
      get :index, player_id: player
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_show
    stub_mit do
      get :show, id: Link.first
    end

    assert_template :_link
    assert_template :show
    assert_template 'layouts/application'
    assert_response :success
  end

  def test_destroy
    assert_difference -> { Link.count }, -1, 'expect different count' do
      delete :destroy, id: Link.first
    end

    assert_template nil
    assert_redirected_to admin_links_url
  end
end
