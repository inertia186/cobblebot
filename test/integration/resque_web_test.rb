require 'test_helper'

class ResqueWebTest < ActionDispatch::IntegrationTest
  def test_mount_requires_valid_basic_authentication
    get '/admin/resque/'

    assert_response :unauthorized
    assert_match 'Basic realm=', response.headers['WWW-Authenticate']

    get '/admin/resque/', headers: authorization_headers('wrong-password')

    assert_response :unauthorized
  end

  def test_authenticated_mount_redirects_to_overview
    get '/admin/resque/', headers: authorization_headers(Preference.web_admin_password)

    assert_redirected_to '/admin/resque/overview'
  end

  def test_authenticated_static_asset_is_served_under_mount_path
    get '/admin/resque/style.css', headers: authorization_headers(Preference.web_admin_password)

    assert_response :success
    assert_match 'text/css', response.media_type
    assert_includes response.body, '#main'
  end

  private

  def authorization_headers(password)
    credentials = ActionController::HttpAuthentication::Basic.encode_credentials('admin', password)
    {'HTTP_AUTHORIZATION' => credentials}
  end
end