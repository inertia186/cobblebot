require 'test_helper'

class SuggestionsControllerTest < ActionController::TestCase
  def test_routing
    assert_routing '/suggestion/topics/main', controller: 'suggestions', action: 'show',
      group: 'topics', key: 'main'
  end

  def test_show_renders_the_requested_suggestion_without_a_layout
    Server.mock_mode(up: true) do
      get :show, params: {group: 'topics', key: 'main'}
    end

    assert_response :success
    assert_template 'suggestions/topics/main'
    assert_template layout: nil
    assert_includes response.body, 'Explanation of Topics'
  end

  def test_show_rejects_an_unknown_suggestion
    Server.mock_mode(up: true) do
      get :show, params: {group: 'missing', key: 'missing'}
    end


    assert_response :not_found
  end

  def test_show_rejects_template_traversal
    Server.mock_mode(up: true) do
      get :show, params: {group: '..', key: 'main'}
    end

    assert_response :not_found
  end
end
