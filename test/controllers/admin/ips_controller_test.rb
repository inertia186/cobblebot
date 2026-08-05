require 'test_helper'

class Admin::IpsControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true
  end

  def test_routing
    assert_routing 'admin/ips', controller: 'admin/ips', action: 'index'
  end

  def test_requires_an_authenticated_admin
    session.delete(:admin_signed_in)

    get :index

    assert_redirected_to new_admin_session_url
  end

  def test_atom_feed_requires_valid_basic_authentication
    request.headers['Authorization'] = ActionController::HttpAuthentication::Basic.
      encode_credentials('admin', 'wrong-password')

    get :index, params: {format: :atom}

    assert_response :unauthorized
    assert_match 'Basic realm="Feed Administration"', response.headers['WWW-Authenticate']
  end

  def test_atom_feed_accepts_valid_basic_authentication
    session.delete(:admin_signed_in)
    request.headers['Authorization'] = ActionController::HttpAuthentication::Basic.
      encode_credentials('admin', Preference.web_admin_password)

    get :index, params: {format: :atom, address: ips(:homeip).address}

    assert_response :success
    assert_template :index
    assert_includes response.body, ips(:homeip).address
  end

  def test_index_filters_by_each_routed_attribute
    ip = ips(:homeip)

    expected = {
      address: [ip.id],
      player_id: Ip.where(player_id: ip.player_id).pluck(:id),
      origin: [ip.id],
      cc: [ip.id]
    }
    values = {address: ip.address, player_id: ip.player_id, origin: ip.origin, cc: ip.cc}

    values.each do |key, value|
      get :index, params: {key => value}

      assert_equal expected.fetch(key).sort, assigns(:ips).map(&:id).sort, "expected #{key} filter"
      assert_response :success
    end
  end

  def test_index_applies_query_date_sort_and_pagination
    ip = ips(:homeip)
    ip.update_column(:created_at, Time.current)

    get :index, params: {
      query: ip.player.nick,
      filter: 'only_today',
      sort_field: 'address',
      sort_order: 'asc',
      page: 1
    }

    assert_includes assigns(:ips).map(&:id), ip.id
    assert_equal 'only_today', assigns(:filter)
    assert_equal 'address', assigns(:sort_field)
    assert_equal 'asc', assigns(:sort_order)
    assert_template :index
    assert_response :success
  end
end
