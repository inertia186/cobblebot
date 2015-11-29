require 'test_helper'

class Admin::PreferencesControllerTest < ActionController::TestCase
  def setup
    session[:admin_signed_in] = true
    Preference.slack_api_key = "ID12345678"
  end

  def test_routings
    assert_routing('admin/preferences', controller: 'admin/preferences', action: 'index')
    assert_routing('admin/preferences/edit_cell', controller: 'admin/preferences', action: 'edit_cell')
    assert_routing('admin/preferences/slack_group_element', controller: 'admin/preferences', action: 'slack_group_element')
    assert_routing({ method: 'patch', path: 'admin/preferences/42' }, controller: 'admin/preferences', action: 'update', id: '42')
  end

  def test_index
    get :index

    assert_template :index
    assert_response :success
  end

  def test_index_json
    get :index, format: :json

    assert JSON.parse(response.body), 'expect valid json'

    assert_template :index
    assert_response :success
  end

  def test_edit_cell
    get :edit_cell

    assert_template :edit_cell
    assert_response :success
  end

  def test_slack_group_element

    stub_auth_test(Preference.slack_api_key) do
      stub_groups_list(Preference.slack_api_key) do
        get :slack_group_element
      end
    end

    assert_template :slack_group_element
    assert_response :success
  end

  def test_update
    preference = Preference.first
    preference_params = {
      value: 'value'
    }

    post :update, format: :json, id: preference, preference: preference_params

    preference = assigns :preference
    assert preference.errors.empty?, preference.errors.inspect

    assert_template nil
    assert_response :success
  end

  def test_update_fail
    preference = Preference.where("key LIKE '%_json'").first
    preference_params = {
      value: 'WRONG'
    }

    post :update, format: :json, id: preference, preference: preference_params

    preference = assigns :preference
    refute preference.errors.empty?

    assert_template nil
    assert_response :unprocessable_entity
  end
end
