require 'test_helper'

class Admin::ConfigControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true
  end

  def test_server_properties_routing
    assert_routing 'admin/config/server_properties',
      controller: 'admin/config', action: 'show_server_properties'
  end

  def test_show_server_properties
    ServerProperties.stub(:keys_as_strings, []) { get :show_server_properties }

    assert_response :success
    assert_template :show_server_properties
  end

  def test_requires_an_authenticated_admin
    session.delete(:admin_signed_in)

    get :show_server_properties

    assert_redirected_to new_admin_session_url
  end
end
