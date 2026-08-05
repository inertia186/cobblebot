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

  def test_index_from_author
    get :index, params: { author_id: @player.id }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_equal [@player.id], messages.pluck(:author_id).uniq,
      "expect only messages from #{@player.nick}"

    assert_template :index
    assert_response :success
  end

  def test_index_feed
    basic = ActionController::HttpAuthentication::Basic
    credentials = basic.encode_credentials('admin', Preference.web_admin_password)
    request.headers['Authorization'] = credentials

    get :index, params: { format: :atom }
    messages = assigns :messages
    refute_equal messages.count(:all), 0, 'did not expect zero count'

    assert_template :index
    assert_response :success
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
end
