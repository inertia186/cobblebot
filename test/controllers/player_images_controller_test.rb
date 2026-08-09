require 'test_helper'

class PlayerImagesControllerTest < ActionController::TestCase
  include WebStubs

  def test_routings
    assert_routing({ method: 'get', path: '/player_images/inertia186/16.png' }, controller: 'player_images', action: 'show', id: 'inertia186', size: '16', format: 'png')
  end

  def test_show
    stub_minotar('inertia186', '16', 'png') do
      get :show, params: { id: 'inertia186', size: '16', format: :png }
    end

    assert_response :success
    assert_equal 'image/png', response.media_type
    assert_includes response.headers['Cache-Control'], 'max-age=7200'
    assert_predicate response.headers['ETag'], :present?
    refute_match(/\AW\//, response.headers['ETag'])
  end

  def test_show_ignores_a_nonmatching_if_none_match
    request.headers['If-None-Match'] = '"not-the-current-player"'

    stub_minotar('inertia186', '16', 'png') do
      get :show, params: {id: 'inertia186', size: '16', format: :png}
    end

    assert_response :success
  end

  def test_show_refetches_and_returns_not_modified_for_unchanged_image_bytes
    player = Player.find_by_nick('inertia186')
    url = minotar_url(player.nick, '17', 'png')

    with_minotar_responses(
      player.nick,
      '17',
      'png',
      {status: 200, body: 'unchanged-avatar'},
      {status: 200, body: 'unchanged-avatar'}
    ) do
      get :show, params: {id: player.nick, size: '17', format: :png}
      current_etag = response.headers.fetch('ETag')
      request.headers['If-None-Match'] = current_etag

      get :show, params: {id: player.nick, size: '17', format: :png}

      assert_requested :get, url, times: 2
    end

    assert_response :not_modified
    assert_includes response.headers['Cache-Control'], 'max-age=7200'
  end

  def test_show_returns_changed_bytes_and_etag_for_the_same_player_uuid
    player = Player.find_by_nick('inertia186')
    uuid = player.uuid
    url = minotar_url(player.nick, '18', 'png')

    with_minotar_responses(
      player.nick,
      '18',
      'png',
      {status: 200, body: 'first-avatar'},
      {status: 200, body: 'second-avatar'}
    ) do
      get :show, params: {id: player.nick, size: '18', format: :png}
      original_etag = response.headers.fetch('ETag')
      request.headers['If-None-Match'] = original_etag

      get :show, params: {id: player.nick, size: '18', format: :png}

      assert_requested :get, url, times: 2
      assert_response :success
      assert_equal 'second-avatar', response.body
      refute_equal original_etag, response.headers.fetch('ETag')
      assert_equal uuid, player.reload.uuid
    end
  end

  def test_show_uses_a_stable_content_etag_for_the_fallback_image
    url = minotar_url('Notch', '19', 'png')

    with_minotar_responses(
      'Notch',
      '19',
      'png',
      {status: 404},
      {status: 404}
    ) do
      get :show, params: {id: 'Notch', size: '19', format: :png}
      fallback_etag = response.headers.fetch('ETag')
      request.headers['If-None-Match'] = fallback_etag

      get :show, params: {id: 'Notch', size: '19', format: :png}

      assert_requested :get, url, times: 2
    end

    assert_response :not_modified
  end

  def test_show_missing
    stub_minotar('Notch', '16', 'png') do
      get :show, params: { id: 'Notch', size: '16', format: :png }
    end

    assert_response :success
    assert_equal 'image/png', response.media_type
  end

  def test_show_redirected
    File.stub(:read, nil) do
      stub_minotar('Notch', '16', 'png') do
        get :show, params: { id: 'Notch', size: '16', format: :png }
      end
    end

    assert_redirected_to 'https://minotar.net/avatar/Notch/16.png'
  end

private
  def minotar_url(nick, size, format)
    "https://minotar.net/avatar/#{nick}/#{size}.#{format}"
  end

  def with_minotar_responses(nick, size, format, *responses)
    stub = stub_request(:get, minotar_url(nick, size, format))
      .to_return(*responses)
    yield
  ensure
    remove_request_stub stub if stub
  end
end
