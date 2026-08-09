require 'test_helper'

class Admin::SuggestionsControllerTest < ActionController::TestCase
  def test_routing
    assert_routing(
      { method: 'get', path: 'admin/suggestion/callbacks/main' },
      controller: 'admin/suggestions', action: 'show',
      group: 'callbacks', key: 'main'
    )
  end

  def test_show_renders_an_allowlisted_suggestion_for_an_admin
    session[:admin_signed_in] = true

    get :show, params: { group: 'callbacks', key: 'main' }

    assert_template 'admin/suggestions/callbacks/main'
    assert_response :success
  end

  def test_callback_explanation_rows_are_inside_table_bodies
    session[:admin_signed_in] = true

    %w[command type].each do |key|
      get :show, params: { group: 'callbacks', key: key }

      assert_response :success
      assert_select 'table > tr', count: 0
      assert_select 'table > tbody > tr', minimum: 1
    end
  end

  def test_show_requires_an_authenticated_admin
    get :show, params: { group: 'callbacks', key: 'main' }

    assert_redirected_to new_admin_session_url
  end

  def test_show_rejects_a_template_outside_the_allowlist
    session[:admin_signed_in] = true

    get :show, params: { group: 'callbacks', key: 'missing' }

    assert_response :not_found
  end
end
