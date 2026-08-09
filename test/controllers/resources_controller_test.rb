require 'test_helper'

class ResourcesControllerTest < ActionController::TestCase
  def test_routing
    assert_routing 'server-icon.png', controller: 'resources', action: 'server_icon'
  end

  def test_missing_server_icon_returns_not_found
    request_icon(nil)

    assert_response :not_found
  end

  def test_server_icon_has_content_etag_and_two_hour_public_cache
    request_icon('first icon')

    assert_response :success
    assert_equal 'image/png', response.media_type
    assert_equal 'first icon', response.body
    assert response.headers['ETag'].present?
    assert_match(/max-age=7200/, response.headers['Cache-Control'])
    assert_match(/public/, response.headers['Cache-Control'])
  end

  def test_fresh_server_icon_returns_not_modified
    request_icon('first icon')
    etag = response.headers['ETag']

    @request.headers['If-None-Match'] = etag
    request_icon('first icon')

    assert_response :not_modified
    assert_empty response.body
  end

  def test_matching_etag_takes_precedence_over_stale_modified_since
    request_icon('first icon')
    etag = response.headers['ETag']

    @request.headers['If-None-Match'] = etag
    @request.headers['If-Modified-Since'] = Time.at(0).httpdate
    request_icon('first icon')

    assert_response :not_modified
    assert_empty response.body
  end

  def test_changed_server_icon_invalidates_the_old_etag
    request_icon('first icon')
    old_etag = response.headers['ETag']

    @request.headers['If-None-Match'] = old_etag
    request_icon('second icon')

    assert_response :success
    refute_equal old_etag, response.headers['ETag']
    assert_equal 'second icon', response.body
  end

private
  def request_icon(content)
    Server.mock_mode(up: true) do
      Server.stub(:server_icon, content) { get :server_icon }
    end
  end
end
