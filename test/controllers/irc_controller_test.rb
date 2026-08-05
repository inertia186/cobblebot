require 'test_helper'

class IrcControllerTest < ActionController::TestCase
  def test_routing_defaults_to_javascript
    assert_routing 'irc', controller: 'irc', action: 'index', format: 'js'
  end

  def test_index_renders_the_active_irc_count_as_javascript
    Server.mock_mode(up: true) do
      get :index, params: {format: :js}
    end

    assert_response :success
    assert_equal 'text/javascript', response.media_type
    assert_match "c = #{Preference.active_in_irc.to_i}", response.body
  end
end
