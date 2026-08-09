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
    stub_mit do
      stub_github do
        get :index
      end
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_sort_by_link_linked_by
    stub_mit do
      stub_github do
        get :index, params: { sort_field: 'link_linked_by' }
      end
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_advertises_the_authenticated_feed_without_exposing_the_password
    secret = 'sentinel-admin-password'
    Preference.find_by!(key: Preference::WEB_ADMIN_PASSWORD).update!(value: secret)

    stub_mit do
      stub_github do
        get :index
      end
    end

    refute_includes response.body, secret
    assert_select 'link[rel="alternate"][type="application/atom+xml"]', count: 1 do |links|
      assert_equal admin_links_url(format: :atom), links.first['href']
    end
    assert_select "a[href='#{admin_resque_server_url}']", text: 'Resque'
    assert_targeted_external_links_are_isolated
  end

  def test_atom_feed_requires_basic_authentication
    session.delete(:admin_signed_in)

    get :index, params: {format: :atom}

    assert_response :unauthorized
    assert_match 'Basic realm="Feed Administration"',
      response.headers['WWW-Authenticate']
  end

  def test_atom_feed_rejects_invalid_basic_authentication
    session.delete(:admin_signed_in)
    request.headers['Authorization'] = basic_credentials('wrong-password')

    get :index, params: {format: :atom}

    assert_response :unauthorized
    assert_match 'Basic realm="Feed Administration"',
      response.headers['WWW-Authenticate']
  end

  def test_atom_feed_accepts_valid_basic_authentication
    session.delete(:admin_signed_in)
    request.headers['Authorization'] = basic_credentials(
      Preference.web_admin_password
    )

    stub_mit do
      stub_github do
        get :index, params: { format: :atom }
      end
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_query
    stub_mit do
      get :index, params: { query: 'mit' }
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
      get :index, params: { player_id: player }
    end
    links = assigns :links
    refute_equal links.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_show
    stub_mit do
      get :show, params: { id: Link.first }
    end

    assert_template :_link
    assert_template :show
    assert_template 'layouts/application'
    assert_response :success
    assert_targeted_external_links_are_isolated
  end

  def test_destroy
    assert_difference -> { Link.count }, -1, 'expect different count' do
      delete :destroy, params: { id: Link.first }
    end

    assert_template nil
    assert_redirected_to admin_links_url
  end


private
  def basic_credentials(password)
    ActionController::HttpAuthentication::Basic.
      encode_credentials('admin', password)
  end

  def assert_targeted_external_links_are_isolated
    links = css_select("a[href^='http'][target]")
    assert_predicate links, :present?

    links.each do |link|
      rel = link['rel'].to_s.split
      assert_includes rel, 'noopener'
      assert_includes rel, 'noreferrer'
    end
  end
end
