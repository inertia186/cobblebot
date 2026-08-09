require 'test_helper'

class Admin::MessagesControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true

    @player = Player.first
    author = Player.last
    assert_difference -> { @player.messages.count }, 1, 'expect different count' do
      @player.messages.create(author: author, body: 'test', recipient_term: "@#{@player.nick}")
    end
  end

  def test_routings
    assert_routing({ method: 'get', path: 'admin/messages' }, controller: 'admin/messages', action: 'index')
  end

  def test_index
    get :index
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_advertises_the_authenticated_feed_without_exposing_the_password
    secret = 'sentinel-admin-password'
    Preference.find_by!(key: Preference::WEB_ADMIN_PASSWORD).update!(value: secret)

    get :index

    refute_includes response.body, secret
    assert_select 'link[rel="alternate"][type="application/atom+xml"]', count: 1 do |links|
      assert_equal admin_messages_url(format: :atom), links.first['href']
    end
  end

  def test_index_from_author
    get :index, params: { author_id: @player.id }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_equal [@player.id], messages.pluck(:author_id).uniq,
      "expect only messages from #{@player.nick}"

    assert_template :index
    assert_response :success
  end

  def test_index_from_author_uses_the_polymorphic_author_type
    message = Message.create!(
      author: @player,
      recipient: Link.first,
      recipient_term: 'external recipient',
      body: 'message with a non-player recipient'
    )

    get :index, params: { author_id: @player.id, filter_modes: 'false' }

    assert_includes assigns(:messages), message
    assert_equal [@player.id], assigns(:messages).pluck(:author_id).uniq
    assert_equal ['Player'], assigns(:messages).pluck(:author_type).uniq
    assert_equal [@player.id], assigns(:author).pluck(:id)
    assert_response :success
  end

  def test_index_etag_changes_when_a_rendered_message_changes
    get :index
    old_etag = response.headers['ETag']
    message = assigns(:messages).first
    message.update!(body: 'updated after the first response')

    request.headers['If-None-Match'] = old_etag
    get :index

    assert_response :success
    refute_equal old_etag, response.headers['ETag']
    assert_includes response.body, 'updated after the first response'
  end

  def test_index_returns_not_modified_for_an_unchanged_etag
    get :index
    etag = response.headers['ETag']

    request.headers['If-None-Match'] = etag
    get :index

    assert_response :not_modified
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

    get :index, params: {format: :atom}
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
    assert_valid_atom_metadata
  end

  def test_empty_atom_feed_has_valid_metadata
    Message.where(type: nil).delete_all
    session.delete(:admin_signed_in)
    request.headers['Authorization'] = basic_credentials(
      Preference.web_admin_password
    )

    get :index, params: {format: :atom}

    assert_response :success
    assert_valid_atom_metadata
  end

  def test_index_query
    get :index, params: { query: 'test' }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_for_players
    get :index, params: { player_id: @player }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_sort_by_message_author_nick
    get :index, params: { sort_field: 'message_author_nick' }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_sort_by_message_recipient_nick
    get :index, params: { sort_field: 'message_recipient_nick' }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_index_sort_by_muted_at
    get :index, params: { sort_field: 'muted_at' }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
  end

  def test_show
    get :show, params: { id: @player.messages.first }
    message = assigns :message
    refute_nil message, 'did not expect nil message'

    assert_template :show
    assert_response :success
  end

  def test_show_redacts_a_missing_author
    message = Message.create!(
      author_type: 'Player', author_id: -1,
      recipient: @player, recipient_term: "@#{@player.nick}", body: 'test'
    )

    get :show, params: {id: message}

    assert_response :success
    assert_includes response.body, '[REDACTED]'
  end

  def test_show_redacts_a_missing_recipient
    message = Message.create!(
      author: @player,
      recipient_type: 'Player', recipient_id: -1,
      recipient_term: 'missing recipient', body: 'test'
    )

    get :show, params: {id: message}

    assert_response :success
    assert_includes response.body, '[REDACTED]'
  end

  def test_destroy
    message = @player.messages.first

    assert_difference -> { Message.count }, -1 do
      delete :destroy, params: {id: message}
    end

    assert_redirected_to admin_messages_url
  end

  def test_destroy_js_removes_the_message_row
    message = @player.messages.first

    assert_difference -> { Message.count }, -1 do
      delete :destroy, params: {id: message, format: :js}, xhr: true
    end

    assert_template :remove_message_row
    assert_response :success
  end

private
  def assert_valid_atom_metadata
    document = Nokogiri::XML(response.body)
    namespace = {'atom' => 'http://www.w3.org/2005/Atom'}
    title = document.at_xpath('/atom:feed/atom:title', namespace)
    updated = document.at_xpath('/atom:feed/atom:updated', namespace)

    assert_predicate title, :present?
    assert_predicate title.text, :present?
    assert_nil document.at_xpath('/atom:feed/atom:body', namespace)
    assert_predicate updated, :present?
    assert Time.iso8601(updated.text)
  end

  def basic_credentials(password)
    ActionController::HttpAuthentication::Basic.
      encode_credentials('admin', password)
  end
end
