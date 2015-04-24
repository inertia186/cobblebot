require 'test_helper'

class Admin::LinksControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true

    stub_request(:head, "http://www.mit.edu/").
      to_return(status: 200)
    stub_request(:head, "http://github.com/inertia186/cobblebot").
      to_return(status: 200)
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
  
  def test_index_feed
    basic = ActionController::HttpAuthentication::Basic 
    credentials = basic.encode_credentials('admin', Preference.web_admin_password)
    request.headers['Authorization'] = credentials
    
    get :index, format: :atom
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'
    
    assert_template :index
    assert_response :success
  end
  
  def test_index
    get :index, query: 'mit'
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
    
    get :index, player_id: player
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'
    
    assert_template :index
    assert_response :success
  end
  
  def test_show
    get :show, id: Link.first

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